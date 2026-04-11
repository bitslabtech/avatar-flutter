import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './entities/product.entity';
import { CreateProductDto, UpdateProductDto } from './dto/product.dto';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { AuditLogActionType, AuditLogStatus } from '../audit-logs/entities/audit-log.entity';

@Injectable()
export class ProductsService {
    constructor(
        @InjectRepository(Product)
        private productsRepository: Repository<Product>,
        private auditLogsService: AuditLogsService,
    ) { }

    async findAll(query?: { page?: number; limit?: number; search?: string; category?: string; isActive?: string }) {
        const page = Math.max(1, Number(query?.page) || 1);
        const limit = Math.min(100, Math.max(1, Number(query?.limit) || 30));
        const skip = (page - 1) * limit;

        const qb = this.productsRepository.createQueryBuilder('product')
            .leftJoinAndSelect('product.brandRel', 'brandRel')
            .leftJoinAndSelect('product.category', 'category')
            .orderBy('product.createdAt', 'DESC')
            .skip(skip)
            .take(limit);

        if (query?.search) {
            const search = `%${query.search.toLowerCase()}%`;
            qb.andWhere(
                '(LOWER(product.name) LIKE :search OR LOWER(product.sku) LIKE :search OR LOWER(product.brand) LIKE :search)',
                { search }
            );
        }

        if (query?.category) {
            qb.andWhere('LOWER(product.category) = LOWER(:category)', { category: query.category });
        }

        if (query?.isActive !== undefined && query.isActive !== '') {
            qb.andWhere('product.isActive = :isActive', { isActive: query.isActive === 'true' });
        }

        const [data, total] = await qb.getManyAndCount();

        return {
            data,
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
        };
    }

    /** Internal: returns all products without pagination (for export/stats) */
    findAllUnpaged() {
        return this.productsRepository.find({
            relations: ['brandRel', 'category'],
            order: { createdAt: 'DESC' },
        });
    }


    async findOne(id: string) {
        const product = await this.productsRepository.findOne({
            where: { id },
            relations: ['brandRel', 'category'],
        });
        if (!product) throw new NotFoundException(`Product with ID ${id} not found`);
        return product;
    }

    async findByVariationGroup(groupId: string) {
        return this.productsRepository.find({
            where: { variationGroupId: groupId },
            relations: ['brandRel', 'category'],
            order: { variationType: 'ASC', variant: 'ASC', size: 'ASC' },
        });
    }

    async create(createProductDto: CreateProductDto, admin?: any, ip?: string) {
        const product = this.productsRepository.create(createProductDto);
        const result = await this.productsRepository.save(product);
        if (admin) {
            await this.auditLogsService.logAction(
                admin.id,
                AuditLogActionType.INVENTORY,
                `Created Product ${result.name}`,
                `Added new product to catalog`,
                ip
            );
        }
        return result;
    }

    async update(id: string, updateProductDto: UpdateProductDto, admin?: any, ip?: string) {
        const product = await this.findOne(id);
        const oldData = { ...product };
        Object.assign(product, updateProductDto);
        const result = await this.productsRepository.save(product);

        if (admin) {
            await this.auditLogsService.logAction(
                admin.id,
                AuditLogActionType.INVENTORY,
                `Updated Product ${result.name}`,
                `Modified product details`,
                ip
            );
        }
        return result;
    }

    async remove(id: string, admin?: any, ip?: string) {
        const product = await this.findOne(id);
        const result = await this.productsRepository.remove(product);
        if (admin) {
            await this.auditLogsService.logAction(
                admin.id,
                AuditLogActionType.DELETE,
                `Deleted Product ${product.name}`,
                `Removed product from catalog`,
                ip
            );
        }
        return result;
    }
}
