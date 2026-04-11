import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import * as ExcelJS from 'exceljs';
import { Product } from '../products/entities/product.entity';
import { PriceChangeLog } from './entities/price-change-log.entity';
import { User } from '../users/entities/user.entity';
import { AppException } from '../../common/exceptions/app.exception';

@Injectable()
export class PricingService {
  constructor(
    @InjectRepository(Product)
    private productRepository: Repository<Product>,
    @InjectRepository(PriceChangeLog)
    private priceChangeLogRepository: Repository<PriceChangeLog>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private dataSource: DataSource,
  ) { }

  async exportToExcel(): Promise<Buffer> {
    const products = await this.productRepository.find({
      order: { sku: 'ASC' },
    });

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Products');

    // Headers
    worksheet.columns = [
      { header: 'SKU', key: 'sku', width: 20 },
      { header: 'Name', key: 'name', width: 40 },
      { header: 'DP Price (₹)', key: 'dpPrice', width: 15 },
      { header: 'MRP (₹)', key: 'mrp', width: 15 },
    ];

    // Add data (convert paise to ₹)
    products.forEach((product) => {
      worksheet.addRow({
        sku: product.sku,
        name: product.name,
        dpPrice: product.price ? Number(product.price).toFixed(2) : '0.00',
        mrp: '', // MRP unavailable
      });
    });

    const buffer = await workbook.xlsx.writeBuffer();
    return Buffer.from(buffer);
  }

  async importFromExcel(
    file: Express.Multer.File,
    changedBy: string,
  ): Promise<{
    successful: number;
    failed: number;
    errors: Array<{ row: number; error: string }>;
  }> {
    // Validate file
    if (
      !file.mimetype.includes('spreadsheet') &&
      !file.mimetype.includes('excel')
    ) {
      throw new AppException(
        'INVALID_FILE',
        'File must be an Excel spreadsheet',
      );
    }

    if (file.size > 10 * 1024 * 1024) {
      // 10MB limit
      throw new AppException('FILE_TOO_LARGE', 'File size exceeds 10MB');
    }

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(file.buffer as any);

    const worksheet = workbook.worksheets[0];
    if (!worksheet) {
      throw new AppException('INVALID_FILE', 'Excel file has no worksheets');
    }

    // Validate headers
    const firstRow = worksheet.getRow(1);
    const headers = firstRow.values as string[];
    const skuIndex = headers.findIndex((h) =>
      h?.toString().toLowerCase().includes('sku'),
    );
    const priceIndex = headers.findIndex(
      (h) =>
        h?.toString().toLowerCase().includes('price') ||
        h?.toString().toLowerCase().includes('dp'),
    );

    if (skuIndex === -1 || priceIndex === -1) {
      throw new AppException(
        'INVALID_FORMAT',
        'Excel must have SKU and DP Price columns',
      );
    }

    const results = {
      successful: 0,
      failed: 0,
      errors: [] as Array<{ row: number; error: string }>,
    };

    // Process rows
    for (let rowNum = 2; rowNum <= worksheet.rowCount; rowNum++) {
      const row = worksheet.getRow(rowNum);
      const sku = row.getCell(skuIndex).value?.toString().trim();
      const priceStr = row.getCell(priceIndex).value?.toString().trim();

      if (!sku) {
        results.failed++;
        results.errors.push({
          row: rowNum,
          error: 'SKU is required',
        });
        continue;
      }

      if (!priceStr) {
        results.failed++;
        results.errors.push({
          row: rowNum,
          error: 'DP Price is required',
        });
        continue;
      }

      const price = parseFloat(priceStr);
      if (isNaN(price) || price < 0) {
        results.failed++;
        results.errors.push({
          row: rowNum,
          error: 'Invalid price value',
        });
        continue;
      }

      // Convert ₹ to paise
      const pricePaise = Math.round(price * 100);

      try {
        await this.updateProductPrice(sku, pricePaise, changedBy);
        results.successful++;
      } catch (error) {
        results.failed++;
        results.errors.push({
          row: rowNum,
          error: error.message || 'Failed to update product',
        });
      }
    }

    return results;
  }

  private async updateProductPrice(
    sku: string,
    newDpPaise: number,
    changedBy: string,
  ) {
    const product = await this.productRepository.findOne({ where: { sku } });

    if (!product) {
      throw new NotFoundException(`Product with SKU ${sku} not found`);
    }

    const oldDpPaise = product.price ? Math.round(Number(product.price) * 100) : 0;

    // Update product - convert paise back to decimal for storage
    product.price = newDpPaise / 100;
    await this.productRepository.save(product);

    // Log price change
    const log = this.priceChangeLogRepository.create({
      productId: product.id,
      sku: product.sku,
      oldDpPaise,
      newDpPaise,
      changedBy,
      changedAt: new Date(),
    });

    await this.priceChangeLogRepository.save(log);
  }

  async getPriceChanges(filters?: {
    productId?: string;
    sku?: string;
    page?: number;
    limit?: number;
  }) {
    const query = this.priceChangeLogRepository
      .createQueryBuilder('log')
      .leftJoinAndSelect('log.changedByUser', 'user')
      .leftJoinAndSelect('log.product', 'product');

    if (filters?.productId) {
      query.andWhere('log.productId = :productId', {
        productId: filters.productId,
      });
    }

    if (filters?.sku) {
      query.andWhere('log.sku = :sku', { sku: filters.sku });
    }

    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const skip = (page - 1) * limit;

    const [logs, total] = await query
      .skip(skip)
      .take(limit)
      .orderBy('log.changedAt', 'DESC')
      .getManyAndCount();

    return {
      logs: logs.map((log) => ({
        id: log.id,
        sku: log.sku,
        oldDpDisplay: `₹${(log.oldDpPaise / 100).toFixed(2)}`,
        newDpDisplay: `₹${(log.newDpPaise / 100).toFixed(2)}`,
        changedBy: log.changedByUser?.name || log.changedBy,
        changedAt: log.changedAt,
        notes: log.notes,
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
