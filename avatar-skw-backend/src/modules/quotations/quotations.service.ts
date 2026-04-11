import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Quotation, QuotationStatus } from './entities/quotation.entity';
import { QuotationItem } from './entities/quotation-item.entity';
import { Product } from '../products/entities/product.entity';
import { User, UserRole } from '../users/entities/user.entity';
import { CreateOrderDto } from '../orders/dto/orders.dto';
import { OrderNumberService } from '../orders/order-number.service';
import { CourierService } from '../courier/courier.service';
import { WhatsAppService } from '../whatsapp/whatsapp.service';
import { AppException } from '../../common/exceptions/app.exception';

@Injectable()
export class QuotationsService {
  constructor(
    @InjectRepository(Quotation)
    private quotationRepository: Repository<Quotation>,
    @InjectRepository(QuotationItem)
    private quotationItemRepository: Repository<QuotationItem>,
    @InjectRepository(Product)
    private productRepository: Repository<Product>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private orderNumberService: OrderNumberService,
    private courierService: CourierService,
    private whatsappService: WhatsAppService,
    private dataSource: DataSource,
  ) { }

  async createQuotation(userId: string, createDto: CreateOrderDto) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: ['dealerTier'],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Validate and fetch products
    const productIds = createDto.items.map((item) => item.productId);
    const products = await this.productRepository.find({
      where: productIds.map((id) => ({ id })),
    });

    if (products.length !== productIds.length) {
      throw new AppException(
        'INVALID_PRODUCTS',
        'One or more products not found',
      );
    }

    // Calculate totals in paise
    let subtotalDpPaise = 0;
    const quotationItems: Partial<QuotationItem>[] = [];

    for (const itemDto of createDto.items) {
      const product = products.find((p) => p.id === itemDto.productId);
      if (!product) {
        throw new AppException(
          'INVALID_PRODUCT',
          `Product ${product?.sku || itemDto.productId} is not available`,
        );
      }

      const dpPricePaise = Math.round((Number(product.price) || 0) * 100);
      const lineTotalPaise = dpPricePaise * itemDto.qty;
      subtotalDpPaise += lineTotalPaise;

      quotationItems.push({
        productId: product.id,
        sku: product.sku,
        name: product.name,
        qty: itemDto.qty,
        dpPricePaise: dpPricePaise,
        lineTotalDpPaise: lineTotalPaise,
        taxPercent: product.gstPercent,
      });
    }

    // Apply dealer discount internally
    let discountAppliedPaise = 0;
    if (user.role === UserRole.DEALER && user.dealerTier) {
      const discountPct = user.dealerTier.discountPct;
      discountAppliedPaise = Math.round(
        (subtotalDpPaise * discountPct) / 100,
      );
    }

    const subtotalAfterDiscountPaise = subtotalDpPaise - discountAppliedPaise;

    // Calculate courier fee
    const courierFeePaise = await this.courierService.calculateFee(
      subtotalAfterDiscountPaise,
    );

    // Calculate tax
    const taxableAmountPaise = subtotalAfterDiscountPaise + courierFeePaise;
    const avgTaxPercent =
      quotationItems.reduce((sum, item) => sum + item.taxPercent, 0) /
      quotationItems.length;
    const taxPaise = Math.round((taxableAmountPaise * avgTaxPercent) / 100);

    // Calculate grand total
    const grandTotalPaise =
      subtotalAfterDiscountPaise + courierFeePaise + taxPaise;

    // Generate quotation number
    const quotationNo = await this.orderNumberService.generateQuotationNo();

    // Save quotation and items in transaction
    const quotation = await this.dataSource.transaction(async (manager) => {
      const quotationEntity = manager.create(Quotation, {
        quotationNo,
        userId,
        status: QuotationStatus.DRAFT,
        roleSnapshot: {
          role: user.role,
          dealerTierId: user.dealerTierId,
          discountPct: user.dealerTier?.discountPct,
        },
        subtotalDpPaise,
        discountAppliedPaise,
        courierFeePaise,
        taxPaise,
        grandTotalPaise,
        addressSnapshot: createDto.address,
      });

      const savedQuotation = await manager.save(Quotation, quotationEntity);

      // Save quotation items
      const itemsToSave = quotationItems.map((item) =>
        manager.create(QuotationItem, {
          ...item,
          quotationId: savedQuotation.id,
        }),
      );
      await manager.save(QuotationItem, itemsToSave);

      return savedQuotation;
    });

    // Load quotation with items
    const quotationWithItems = await this.quotationRepository.findOne({
      where: { id: quotation.id },
      relations: ['items', 'items.product'],
    });

    // Generate WhatsApp link
    const whatsappLink = await this.whatsappService.sendQuotationNotification(
      quotationWithItems,
      user,
    );

    return {
      id: quotationWithItems.id,
      quotationNo: quotationWithItems.quotationNo,
      status: quotationWithItems.status,
      items: quotationWithItems.items.map((item) => ({
        id: item.id,
        productId: item.productId,
        sku: item.sku,
        name: item.name,
        qty: item.qty,
        dpPricePaise: item.dpPricePaise,
        lineTotalDpPaise: item.lineTotalDpPaise,
      })),
      subtotalDpPaise,
      discountAppliedPaise,
      courierFeePaise,
      taxPaise,
      grandTotalPaise,
      whatsappLink,
      createdAt: quotationWithItems.createdAt,
    };
  }

  async findAll(userId: string, userRole: string) {
    const where: any = { userId };
    if (userRole !== 'admin' && userRole !== 'super_admin') {
      // Regular users only see their own quotations
    }

    return this.quotationRepository.find({
      where,
      relations: ['items'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string, userId: string, userRole: string) {
    const where: any = { id };
    if (userRole !== 'admin' && userRole !== 'super_admin') {
      where.userId = userId;
    }

    const quotation = await this.quotationRepository.findOne({
      where,
      relations: ['items', 'items.product', 'user'],
    });

    if (!quotation) {
      throw new NotFoundException('Quotation not found');
    }

    return this.toQuotationPublicDto(quotation);
  }

  async generateQuotationPdf(id: string): Promise<Buffer> {
    // TODO: Implement PDF generation
    throw new BadRequestException('PDF generation not yet implemented');
  }

  private toQuotationPublicDto(quotation: Quotation) {
    return {
      id: quotation.id,
      quotationNo: quotation.quotationNo,
      status: quotation.status,
      items: quotation.items?.map((item) => ({
        id: item.id,
        productId: item.productId,
        sku: item.sku,
        name: item.name,
        qty: item.qty,
        dpPricePaise: item.dpPricePaise,
        lineTotalDpPaise: item.lineTotalDpPaise,
      })),
      subtotalDpPaise: quotation.subtotalDpPaise,
      discountAppliedPaise: quotation.discountAppliedPaise,
      courierFeePaise: quotation.courierFeePaise,
      taxPaise: quotation.taxPaise,
      grandTotalPaise: quotation.grandTotalPaise,
      addressSnapshot: quotation.addressSnapshot,
      createdAt: quotation.createdAt,
      updatedAt: quotation.updatedAt,
    };
  }
}


