import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, JoinColumn, Index, In } from 'typeorm';
import { Order, OrderStatus } from './entities/order.entity';
import { OrderItem } from './entities/order-item.entity';
import { Product } from '../products/entities/product.entity';
import { User, UserRole } from '../users/entities/user.entity';
import { CreateOrderDto, UpdateOrderStatusDto, CreateOrderOnBehalfDto, ConfirmOrderDto } from './dto/orders.dto';
import { OrderNumberService } from './order-number.service';
import { CourierService } from '../courier/courier.service';
import { WhatsAppService } from '../whatsapp/whatsapp.service';
import { AppException } from '../../common/exceptions/app.exception';
import { AddressesService } from '../addresses/addresses.service';
import { AddressType } from '../addresses/entities/address.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/entities/notification.entity';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { AuditLogActionType, AuditLogStatus } from '../audit-logs/entities/audit-log.entity';
import { SettingsService } from '../settings/settings.service';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
    @InjectRepository(OrderItem)
    private orderItemRepository: Repository<OrderItem>,
    @InjectRepository(Product)
    private productRepository: Repository<Product>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private orderNumberService: OrderNumberService,
    private courierService: CourierService,
    private whatsappService: WhatsAppService,
    private addressesService: AddressesService,
    private notificationsService: NotificationsService,
    private dataSource: DataSource,
    private auditLogsService: AuditLogsService,
    private settingsService: SettingsService,
  ) { }

  async createOrderDraft(userId: string, createOrderDto: CreateOrderDto) {
    console.log('DEBUG: createOrderDraft called with items:', JSON.stringify(createOrderDto.items));
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: ['dealerTier'],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if user already has a draft order - Find ALL drafts to cleanup zombies
    const allDrafts = await this.orderRepository.find({
      where: { userId, status: OrderStatus.DRAFT },
      relations: ['items'],
      order: { updatedAt: 'DESC' },
    });

    const existingDraft = allDrafts.length > 0 ? allDrafts[0] : null;
    const zombieDrafts = allDrafts.length > 1 ? allDrafts.slice(1) : [];

    // Handle empty cart case FIRST (before validation)
    if (createOrderDto.items.length === 0) {
      // Delete ALL draft orders for this user
      for (const draft of allDrafts) {
        await this.orderItemRepository.delete({ orderId: draft.id });
        await this.orderRepository.delete({ id: draft.id });
      }

      return {
        id: null,
        orderNo: null,
        status: 'draft',
        items: [],
        subtotalDpPaise: 0,
        discountAppliedPaise: 0,
        courierFeePaise: 0,
        taxPaise: 0,
        grandTotalPaise: 0,
        dpSubtotalDisplay: 'Ã¢â€šÂ¹0.00',
        courierDisplay: 'Ã¢â€šÂ¹0.00',
        approxTotalDisplay: 'Ã¢â€šÂ¹0.00',
        whatsappLink: '',
        createdAt: new Date().toISOString(),
      };
    }

    // Validate and fetch products
    const productIds = createOrderDto.items.map((item) => item.productId);
    const products = await this.productRepository.find({
      where: productIds.map((id) => ({ id })),
    });

    if (products.length !== productIds.length) {
      throw new AppException(
        'INVALID_PRODUCTS',
        'One or more products not found',
      );
    }

    // Clean up zombie drafts immediately (outside transaction for simplicity/speed)
    if (zombieDrafts.length > 0) {
      // We can run this async without awaiting if we want speed, but safer to await
      for (const zombie of zombieDrafts) {
        await this.orderItemRepository.delete({ orderId: zombie.id });
        await this.orderRepository.delete({ id: zombie.id });
      }
    }

    // Calculate totals in paise
    let subtotalDpPaise = 0;
    const orderItems: Partial<OrderItem>[] = [];

    for (const itemDto of createOrderDto.items) {
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

      orderItems.push({
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

    // Calculate tax (on subtotal + courier)
    const taxableAmountPaise = subtotalAfterDiscountPaise + courierFeePaise;
    const avgTaxPercent =
      orderItems.reduce((sum, item) => sum + item.taxPercent, 0) /
      orderItems.length;
    const taxPaise = Math.round((taxableAmountPaise * avgTaxPercent) / 100);

    // Calculate grand total
    const grandTotalPaise =
      subtotalAfterDiscountPaise + courierFeePaise + taxPaise;

    // Update existing draft or create new one
    const order = await this.dataSource.transaction(async (manager) => {
      let orderEntity: Order;

      if (existingDraft) {
        // Update existing draft
        orderEntity = existingDraft;
        orderEntity.subtotalDpPaise = subtotalDpPaise;
        orderEntity.discountAppliedPaise = discountAppliedPaise;
        orderEntity.courierFeePaise = courierFeePaise;
        orderEntity.taxPaise = taxPaise;
        orderEntity.grandTotalPaise = grandTotalPaise;
        orderEntity.addressSnapshot = createOrderDto.address || orderEntity.addressSnapshot;

        // Delete old items
        await manager.delete(OrderItem, { orderId: existingDraft.id });

        // Clean up any other draft orders for this user (orphaned ones)
        const otherDrafts = await manager.find(Order, {
          where: { userId, status: OrderStatus.DRAFT },
        });
        const orphanedDrafts = otherDrafts.filter(d => d.id !== existingDraft.id);
        if (orphanedDrafts.length > 0) {
          for (const draft of orphanedDrafts) {
            await manager.delete(OrderItem, { orderId: draft.id });
            await manager.delete(Order, { id: draft.id });
          }
        }
      } else {
        // Create new draft
        // Use temporary draft ID
        const orderNo = `DRAFT-${Date.now()}`;
        orderEntity = manager.create(Order, {
          orderNo,
          userId,
          status: OrderStatus.DRAFT,
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
          addressSnapshot: createOrderDto.address,
        });
      }

      const savedOrder = await manager.save(Order, orderEntity);

      // Save order items
      const itemsToSave = orderItems.map((item) =>
        manager.create(OrderItem, {
          ...item,
          orderId: savedOrder.id,
        }),
      );
      await manager.save(OrderItem, itemsToSave);

      return savedOrder;
    });

    // Load order with items
    const orderWithItems = await this.orderRepository.findOne({
      where: { id: order.id },
      relations: ['items', 'items.product'],
    });

    // Generate WhatsApp link
    const whatsappLink = await this.whatsappService.sendOrderNotification(
      orderWithItems,
      user,
    );

    return {
      id: orderWithItems.id,
      orderNo: orderWithItems.orderNo,
      status: orderWithItems.status,
      items: orderWithItems.items.map((item) => ({
        id: item.id,
        productId: item.productId,
        sku: item.sku,
        name: item.name,
        qty: item.qty,
        dpPricePaise: item.dpPricePaise,
        lineTotalDpPaise: item.lineTotalDpPaise,
        imageUrl: item.imageUrl || (item.product?.images?.[0] ?? null),
      })),
      subtotalDpPaise,
      discountAppliedPaise,
      courierFeePaise,
      taxPaise,
      grandTotalPaise,
      whatsappLink,
      createdAt: orderWithItems.createdAt ? new Date(orderWithItems.createdAt).toISOString() : new Date().toISOString(),
    };
  }

  async findAll(
    userId: string,
    userRole: string,
    query?: { page?: number; limit?: number; status?: string; search?: string },
  ) {
    const page = Math.max(1, Number(query?.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query?.limit) || 20));
    const skip = (page - 1) * limit;

    const isAdmin = userRole === 'admin' || userRole === 'super_admin';

    const qb = this.orderRepository
      .createQueryBuilder('order')
      .leftJoinAndSelect('order.items', 'items')
      .leftJoinAndSelect('items.product', 'product')
      .leftJoinAndSelect('order.user', 'user')
      .where('order.status != :draftStatus', { draftStatus: OrderStatus.DRAFT })
      .orderBy('order.createdAt', 'DESC')
      .skip(skip)
      .take(limit);

    if (!isAdmin) {
      qb.andWhere('order.userId = :userId', { userId });
    }

    if (query?.status && query.status !== 'all') {
      qb.andWhere('order.status = :status', { status: query.status });
    }

    if (query?.search) {
      qb.andWhere(
        '(order.orderNo ILIKE :search OR user.name ILIKE :search OR user.phone ILIKE :search)',
        { search: `%${query.search}%` },
      );
    }

    const [orders, total] = await qb.getManyAndCount();

    const data = orders.map(order => ({
      ...order,
      estimatedDeliveryDate: order.estimatedDeliveryDate instanceof Date
        ? order.estimatedDeliveryDate.toISOString()
        : null,
    }));

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }


  async getStats(userId: string, userRole: string) {
    const isAdmin = userRole === 'admin' || userRole === 'super_admin';

    // Single GROUP BY query Ã¢â‚¬â€ replaces 6 separate COUNT queries.
    const qb = this.orderRepository
      .createQueryBuilder('order')
      .select('order.status', 'status')
      .addSelect('COUNT(*)', 'count')
      .where('order.status != :draftStatus', { draftStatus: OrderStatus.DRAFT });

    if (!isAdmin) {
      qb.andWhere('order.userId = :userId', { userId });
    }

    qb.groupBy('order.status');

    const rows: { status: string; count: string }[] = await qb.getRawMany();

    // Assemble into a lookup map
    const countMap = new Map(rows.map(r => [r.status, parseInt(r.count, 10)]));

    const total = rows.reduce((sum, r) => sum + parseInt(r.count, 10), 0);

    return {
      total,
      pending: countMap.get(OrderStatus.PENDING) ?? 0,
      inTransit: countMap.get(OrderStatus.DISPATCHED) ?? 0,
      delivered: countMap.get(OrderStatus.DELIVERED) ?? 0,
      returned: countMap.get('returned') ?? 0,
      cancelled: countMap.get(OrderStatus.CANCELLED) ?? 0,
    };
  }


  async findOne(id: string, userId: string, userRole: string) {
    const where: any = { id };
    if (userRole !== 'admin' && userRole !== 'super_admin') {
      where.userId = userId;
    }

    const order = await this.orderRepository.findOne({
      where,
      relations: ['items', 'items.product', 'user'],
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    return this.toOrderPublicDto(order);
  }

  async updateStatus(
    id: string,
    updateDto: UpdateOrderStatusDto,
    userId: string,
    userRole?: string,
    ip?: string,
  ) {
    console.log('Ã°Å¸â€Â§ SERVICE - updateStatus called with:', { id, updateDto });
    const order = await this.orderRepository.findOne({
      where: { id },
      relations: ['user']
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    console.log('Ã°Å¸â€Â§ SERVICE - Current order state:', {
      id: order.id,
      currentEstDate: order.estimatedDeliveryDate,
      currentCourier: order.courier,
      currentTracking: order.tracking
    });

    // Modify entity directly
    order.status = updateDto.status as OrderStatus;

    if (updateDto.estimatedDeliveryDate) {
      const dateObj = new Date(updateDto.estimatedDeliveryDate);
      console.log('Ã°Å¸â€Â§ SERVICE - Processing date:', {
        input: updateDto.estimatedDeliveryDate,
        dateObj: dateObj,
        dateObjString: dateObj.toString(),
        isValid: !isNaN(dateObj.getTime())
      });
      order.estimatedDeliveryDate = dateObj;
    }

    if (updateDto.courierProvider) {
      console.log('Ã°Å¸â€Â§ SERVICE - Updating courier:', updateDto.courierProvider);
      order.courier = {
        ...(order.courier || {}),
        provider: updateDto.courierProvider,
      };
    }

    if (updateDto.trackingNumber) {
      console.log('Ã°Å¸â€Â§ SERVICE - Updating tracking:', updateDto.trackingNumber);
      order.tracking = {
        ...(order.tracking || {}),
        trackingNumber: updateDto.trackingNumber,
      };
    }

    if (updateDto.notes) {
      order.notes = updateDto.notes;
    }

    // Handle shipping override: if provided and > 0, use it; if explicitly 0 allow free; if null/undefined, keep existing
    if (updateDto.shippingOverridePaise !== undefined) {
      // null means "remove override and revert to standard charge"
      if (updateDto.shippingOverridePaise === null) {
        order.shippingOverridePaise = null;
        // Recalculate using standard courier fee
        const standardFee = await this.courierService.calculateFee(Number(order.subtotalDpPaise) - Number(order.discountAppliedPaise));
        order.courierFeePaise = standardFee;
      } else {
        order.shippingOverridePaise = Number(updateDto.shippingOverridePaise);
        order.courierFeePaise = order.shippingOverridePaise;
      }
      // Recalculate grand total (keep existing tax values - items not changed)
      const subtotalAfterDiscount = Number(order.subtotalDpPaise) - Number(order.discountAppliedPaise);
      const newGrandTotal = subtotalAfterDiscount + Number(order.courierFeePaise) + Number(order.taxPaise);
      order.grandTotalPaise = newGrandTotal;
    }

    console.log('Ã°Å¸â€Â§ SERVICE - Entity before save:', {
      status: order.status,
      estimatedDeliveryDate: order.estimatedDeliveryDate,
      courier: order.courier,
      tracking: order.tracking
    });

    const saved = await this.orderRepository.save(order);
    console.log('Ã¢Å“â€¦ SERVICE - Save executed successfully');

    console.log('Ã°Å¸â€Â§ SERVICE - Saved result:', {
      id: saved.id,
      estimatedDeliveryDate: saved.estimatedDeliveryDate,
      courier: saved.courier,
      tracking: saved.tracking
    });

    // Send Status Update Notification (WhatsApp)
    if (saved.user) {
      this.whatsappService.sendOrderNotification(saved, saved.user, true)
        .catch(err => console.error('Failed to send order update WhatsApp', err));

      // Send In-App Notification
      let notifTitle = `Order ${updateDto.status}`;
      let notifBody = `Your order #${saved.orderNo} status has been updated to ${updateDto.status}.`;

      if (updateDto.status === OrderStatus.DISPATCHED) {
        notifTitle = 'Order Dispatched';
        notifBody = `Your order #${saved.orderNo} has been dispatched via ${saved.courier?.provider}. Tracking: ${saved.tracking?.trackingNumber}`;
      } else if (updateDto.status === OrderStatus.DELIVERED) {
        notifTitle = 'Order Delivered';
        notifBody = `Your order #${saved.orderNo} has been delivered successfully.`;
      } else if (updateDto.status === OrderStatus.CANCELLED) {
        notifTitle = 'Order Cancelled';
        notifBody = `Your order #${saved.orderNo} has been cancelled.`;
      }

      this.notificationsService.create(
        saved.userId,
        notifTitle,
        notifBody,
        NotificationType.ORDER_UPDATE,
        { orderId: saved.id }
      ).catch(err => console.error('Failed to send in-app notification', err));
    }

    // Verify with raw query
    const raw = await this.orderRepository.query(
      'SELECT estimated_delivery_date, courier, tracking FROM orders WHERE id = $1',
      [id]
    );
    console.log('Ã°Å¸â€Â SERVICE - Raw DB verification:', raw[0]);

    // Manually serialize date for JSON response
    // Audit Log for Admin actions
    if (userRole === UserRole.ADMIN || userRole === UserRole.SUPER_ADMIN) {
      let details = '';
      if (updateDto.status) details += `Status changed to ${updateDto.status}. `;
      if (updateDto.estimatedDeliveryDate) details += `Delivery date updated. `;
      if (updateDto.courierProvider) details += `Courier set to ${updateDto.courierProvider}. `;
      if (updateDto.trackingNumber) details += `Tracking updated. `;

      this.auditLogsService.logAction(
        userId,
        AuditLogActionType.ORDER,
        `Updated Order ${saved.orderNo}`,
        details.trim(),
        ip
      ).catch(err => console.error('Failed to log admin action', err));
    }

    return {
      ...saved,
      estimatedDeliveryDate: saved.estimatedDeliveryDate instanceof Date
        ? saved.estimatedDeliveryDate.toISOString()
        : null,
    };
  }

  /**
   * Update order items (Admin only) - replaces all items with new list
   */
  async updateOrderItems(
    orderId: string,
    items: { productId: string; qty: number }[],
    adminId: string,
    ip?: string,
  ) {
    const order = await this.orderRepository.findOne({
      where: { id: orderId },
      relations: ['items'],
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    // Start a transaction to update items
    const result = await this.dataSource.transaction(async (manager) => {
      // Delete existing items using QueryBuilder for explicit control
      await manager
        .createQueryBuilder()
        .delete()
        .from(OrderItem)
        .where("order_id = :orderId", { orderId })
        .execute();

      // Fetch all products for the new items
      const productIds = items.map((i) => i.productId);
      const products = await manager.find(Product, {
        where: { id: In(productIds) },
      });

      // Deduplicate items (sum quantities if duplicate product in list)
      const consolidatedItems = new Map<string, number>();
      for (const item of items) {
        const currentQty = consolidatedItems.get(item.productId) || 0;
        consolidatedItems.set(item.productId, currentQty + item.qty);
      }

      // Create new order items
      let subtotalPaise = 0;
      let taxPaise = 0;
      const newOrderItems: OrderItem[] = [];

      for (const [productId, qty] of consolidatedItems.entries()) {
        const product = products.find((p) => p.id === productId);
        if (!product) {
          throw new BadRequestException(`Product ${productId} not found`);
        }

        const priceNum = typeof product.price === 'string'
          ? parseFloat(product.price)
          : (product.price ?? 0);
        const dpPricePaise = Math.round(priceNum * 100);
        const lineTotalPaise = dpPricePaise * qty;
        const gstPercent = product.gstPercent ?? 0;
        const itemTaxPaise = Math.round((lineTotalPaise * gstPercent) / 100);

        const orderItem = manager.create(OrderItem, {
          orderId: orderId,
          productId: product.id,
          sku: product.sku,
          name: product.name,
          qty: qty,
          dpPricePaise: dpPricePaise,
          lineTotalDpPaise: lineTotalPaise,
          taxPercent: gstPercent,
          imageUrl: product.images?.[0] ?? null,
        });

        newOrderItems.push(orderItem);
        subtotalPaise += lineTotalPaise;
        taxPaise += itemTaxPaise;
      }

      // Save new items
      await manager.save(OrderItem, newOrderItems);

      // Update order totals using update() to bypass relation cascading issues
      const courierFee = order.courierFeePaise ? Number(order.courierFeePaise) : 0;
      const grandTotal = subtotalPaise + taxPaise + courierFee;

      await manager.update(Order, { id: orderId }, {
        subtotalDpPaise: subtotalPaise,
        taxPaise: taxPaise,
        grandTotalPaise: grandTotal,
      });

      // Log the action (must be outside transaction or using hooked service, but we are in service)
      // Since audit service uses its own repo, we can call it but better to await it after transaction or no-await
      // But we are inside transaction callback.
      // We'll log AFTER returning from transaction wrapper to be safe/clean
      return { success: true, message: 'Order items updated' };
    });

    // Log outside transaction
    this.auditLogsService.logAction(
      adminId,
      AuditLogActionType.ORDER,
      `Updated Items for Order ${order.orderNo}`,
      `Modified order items list`,
      ip
    ).catch(console.error);

    return result;
  }

  async generateProformaInvoice(id: string): Promise<Buffer> {
    // Load order with all relations
    const order = await this.orderRepository.findOne({
      where: { id },
      relations: ['items', 'items.product', 'user'],
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    // Pull business / company settings
    const [companyName, companyAddress, companyPhone, companyAltPhone, companyEmail, companyGstin, taxNotes] =
      await Promise.all([
        this.settingsService.getSetting('business.company_name'),
        this.settingsService.getSetting('business.address'),
        this.settingsService.getSetting('business.phone'),
        this.settingsService.getSetting('business.alt_phone'),
        this.settingsService.getSetting('business.email'),
        this.settingsService.getSetting('business.gstin'),
        this.settingsService.getSetting('tax.notes'),
      ]);

    // Helper: paise Ã¢â€ â€™ formatted string using "Rs." (PDFKit Helvetica is WinAnsi,
    // cannot render the Ã¢â€šÂ¹ Unicode glyph Ã¢â‚¬â€ renders as a stray "1" superscript)
    const fmt = (paise: number) =>
      (Number(paise) / 100).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');

    return new Promise<Buffer>((resolve, reject) => {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const PDFDocument = require('pdfkit');
      const doc = new PDFDocument({ margin: 50, size: 'A4' });
      const chunks: Buffer[] = [];

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Ã¢â€â‚¬Ã¢â€â‚¬ Colour palette Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      const BRAND   = '#1A56DB';   // primary blue
      const DARK    = '#111827';
      const MUTED   = '#6B7280';
      const LIGHT_BG = '#F3F4F6';
      const WHITE   = '#FFFFFF';
      const RULE    = '#E5E7EB';

      const PAGE_W = doc.page.width  - 100; // usable width (margins 50 each side)

      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      // HEADER BAND
      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      doc.rect(50, 40, PAGE_W, 100).fill(BRAND);

      // Company name
      doc.fillColor(WHITE).font('Helvetica-Bold').fontSize(20)
        .text(companyName || 'Avatar Home Appliances', 60, 55, { width: PAGE_W * 0.6 });

      // Tag line below
      doc.fillColor('#CBD5E1').font('Helvetica').fontSize(8)
        .text('PROFORMA GST INVOICE', 60, 80);

      // Company contact block (right side of header)
      const headerRight = 50 + PAGE_W * 0.55;
      const headerRightW = PAGE_W * 0.42;
      let hdrContactY = 50;
      doc.fillColor('#DBEAFE').font('Helvetica').fontSize(8);
      if (companyAddress) {
        doc.text(companyAddress, headerRight, hdrContactY, { width: headerRightW, align: 'right' });
        hdrContactY += 14;
      }
      if (companyPhone) {
        doc.text(`Ph: ${companyPhone}`, headerRight, hdrContactY, { width: headerRightW, align: 'right' });
        hdrContactY += 11;
      }
      if (companyAltPhone) {
        doc.text(`Alt: ${companyAltPhone}`, headerRight, hdrContactY, { width: headerRightW, align: 'right' });
        hdrContactY += 11;
      }
      if (companyEmail) {
        doc.text(companyEmail, headerRight, hdrContactY, { width: headerRightW, align: 'right' });
        hdrContactY += 11;
      }
      if (companyGstin) {
        doc.text(`GSTIN: ${companyGstin}`, headerRight, hdrContactY, { width: headerRightW, align: 'right' });
      }

      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      // INVOICE META  (Invoice No / Date / Status)
      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      const metaY = 158;
      doc.fillColor(DARK).font('Helvetica-Bold').fontSize(11)
        .text('INVOICE DETAILS', 50, metaY);
      doc.moveTo(50, metaY + 14).lineTo(50 + PAGE_W, metaY + 14).stroke(RULE);

      const metaDataY = metaY + 22;
      const col2X = 50 + PAGE_W / 2;

      // Left column
      doc.fillColor(MUTED).font('Helvetica').fontSize(8).text('Invoice / Order No', 50, metaDataY);
      doc.fillColor(DARK).font('Helvetica-Bold').fontSize(10).text(`#${order.orderNo}`, 50, metaDataY + 12);

      doc.fillColor(MUTED).font('Helvetica').fontSize(8).text('Issue Date', 50, metaDataY + 30);
      doc.fillColor(DARK).font('Helvetica').fontSize(9)
        .text(new Date(order.createdAt).toLocaleDateString('en-IN', { day: '2-digit', month: 'long', year: 'numeric' }),
          50, metaDataY + 42);

      // Right column
      doc.fillColor(MUTED).font('Helvetica').fontSize(8).text('Order Status', col2X, metaDataY);
      doc.fillColor(DARK).font('Helvetica-Bold').fontSize(10)
        .text(order.status.toUpperCase(), col2X, metaDataY + 12);

      doc.fillColor(MUTED).font('Helvetica').fontSize(8).text('Payment Method', col2X, metaDataY + 30);
      doc.fillColor(DARK).font('Helvetica').fontSize(9)
        .text(order.paymentMethod || 'Cash on Delivery', col2X, metaDataY + 42);

      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      // BILL TO
      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      const billY = metaDataY + 70;
      doc.rect(50, billY, PAGE_W, 14).fill(LIGHT_BG);
      doc.fillColor(DARK).font('Helvetica-Bold').fontSize(9)
        .text('BILL TO', 54, billY + 3);

      const addr = order.addressSnapshot || {};
      const buyerName  = addr['name']  || order.user?.name  || 'Customer';
      const buyerPhone = addr['phone'] || order.user?.phone || '';
      const addrLine   = [addr['street'], addr['city'], addr['state'], addr['zipCode']]
        .filter(Boolean).join(', ');
      const buyerGstin = order.user?.gstVat;

      let byY = billY + 20;
      doc.fillColor(DARK).font('Helvetica-Bold').fontSize(10).text(buyerName, 50, byY);
      byY += 13;
      doc.fillColor(MUTED).font('Helvetica').fontSize(8).text(addrLine, 50, byY, { width: PAGE_W * 0.55 });
      byY += 12;
      if (buyerPhone) {
        doc.text(`Ph: ${buyerPhone}`, 50, byY);
        byY += 12;
      }
      if (buyerGstin) {
        doc.fillColor(BRAND).font('Helvetica-Bold').fontSize(8).text(`GSTIN: ${buyerGstin}`, 50, byY);
        byY += 12;
      }

      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      // ITEMS TABLE
      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      const tableStartY = Math.max(byY + 20, billY + 90);

      // Table header
      const COL = {
        sr:      { x: 50,  w: 25 },
        sku:     { x: 75,  w: 70 },
        name:    { x: 145, w: 165 },
        qty:     { x: 310, w: 30 },
        price:   { x: 340, w: 75 },
        gstPct:  { x: 415, w: 35 },
        gstAmt:  { x: 450, w: 55 },
        total:   { x: 505, w: 45 + PAGE_W - 505 },
      };

      doc.rect(50, tableStartY, PAGE_W, 16).fill(DARK);
      doc.fillColor(WHITE).font('Helvetica-Bold').fontSize(8);
      const hdrY = tableStartY + 4;
      doc.text('#',           COL.sr.x,    hdrY, { width: COL.sr.w,    align: 'center' });
      doc.text('SKU',         COL.sku.x,   hdrY, { width: COL.sku.w,   align: 'left' });
      doc.text('DESCRIPTION', COL.name.x,  hdrY, { width: COL.name.w,  align: 'left' });
      doc.text('QTY',         COL.qty.x,   hdrY, { width: COL.qty.w,   align: 'center' });
      doc.text('UNIT PRICE',  COL.price.x, hdrY, { width: COL.price.w, align: 'right' });
      doc.text('GST%',        COL.gstPct.x,hdrY, { width: COL.gstPct.w,align: 'center' });
      doc.text('GST AMT',     COL.gstAmt.x,hdrY, { width: COL.gstAmt.w,align: 'right' });
      doc.text('TOTAL',       COL.total.x, hdrY, { width: COL.total.w, align: 'right' });

      let rowY = tableStartY + 16;
      const items = order.items || [];

      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        const dpPricePaise  = Number(item.dpPricePaise);
        const linePaise     = Number(item.lineTotalDpPaise);
        const taxPct        = Number(item.taxPercent) || 0;
        const gstAmtPaise   = Math.round((linePaise * taxPct) / 100);

        const rowBg = i % 2 === 0 ? WHITE : LIGHT_BG;
        doc.rect(50, rowY, PAGE_W, 20).fill(rowBg);

        doc.fillColor(DARK).font('Helvetica').fontSize(8);
        const rY = rowY + 5;
        doc.text(String(i + 1),           COL.sr.x,    rY, { width: COL.sr.w,    align: 'center' });
        doc.text(item.sku || '-',          COL.sku.x,   rY, { width: COL.sku.w,   align: 'left' });
        doc.text(item.name,                COL.name.x,  rY, { width: COL.name.w,  align: 'left', lineBreak: false });
        doc.text(String(item.qty),         COL.qty.x,   rY, { width: COL.qty.w,   align: 'center' });
        doc.text(fmt(dpPricePaise),        COL.price.x, rY, { width: COL.price.w, align: 'right' });
        doc.text(`${taxPct}%`,             COL.gstPct.x,rY, { width: COL.gstPct.w,align: 'center' });
        doc.text(fmt(gstAmtPaise),         COL.gstAmt.x,rY, { width: COL.gstAmt.w,align: 'right' });
        doc.text(fmt(linePaise + gstAmtPaise), COL.total.x, rY, { width: COL.total.w, align: 'right' });

        rowY += 20;
      }

      // Table bottom border
      doc.moveTo(50, rowY).lineTo(50 + PAGE_W, rowY).stroke(DARK);

      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      // SUMMARY BOX (right-aligned)
      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      const summaryX     = 50 + PAGE_W * 0.55;
      const summaryW     = PAGE_W * 0.45;
      let   sumY         = rowY + 16;

      const subtotalDp    = Number(order.subtotalDpPaise);
      const taxDp         = Number(order.taxPaise) || 0;
      const grandDp       = Number(order.grandTotalPaise);

      // No dealer discount, no shipping Ã¢â‚¬â€ only subtotal + GST = grand total
      const summaryRows: [string, string, boolean?][] = [
        ['Subtotal (excl. GST)', fmt(subtotalDp)],
        ['Total GST',            fmt(taxDp)],
      ];

      const drawSummaryRow = (label: string, value: string, bold = false) => {
        doc.fillColor(bold ? DARK : MUTED)
          .font(bold ? 'Helvetica-Bold' : 'Helvetica')
          .fontSize(bold ? 9 : 8)
          .text(label, summaryX, sumY, { width: summaryW * 0.55, align: 'left' })
          .text(value, summaryX + summaryW * 0.55, sumY, { width: summaryW * 0.45, align: 'right' });
        sumY += bold ? 14 : 12;
      };

      for (const [l, v] of summaryRows) drawSummaryRow(l, v);

      // Divider
      doc.moveTo(summaryX, sumY).lineTo(summaryX + summaryW, sumY).stroke(RULE);
      sumY += 6;

      // Grand Total row
      doc.rect(summaryX, sumY, summaryW, 22).fill(BRAND);
      doc.fillColor(WHITE).font('Helvetica-Bold').fontSize(10)
        .text('GRAND TOTAL', summaryX + 6, sumY + 6, { width: summaryW * 0.55, align: 'left' })
        .text(fmt(grandDp),  summaryX + summaryW * 0.55, sumY + 6, { width: summaryW * 0.45, align: 'right' });
      sumY += 22;

      // Ã¢â€â‚¬Ã¢â€â‚¬ Amount in words Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      const totalRupees = Math.floor(grandDp / 100);
      sumY += 10;
      doc.fillColor(MUTED).font('Helvetica').fontSize(7)
        .text(`Amount: ${totalRupees.toLocaleString('en-IN')} (rupees only)`,
          summaryX, sumY, { width: summaryW });

      // Ã¢â€â‚¬Ã¢â€â‚¬ Notes (left side) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      if (order.notes) {
        doc.fillColor(MUTED).font('Helvetica').fontSize(7)
          .text('Notes:', 50, rowY + 16)
          .fillColor(DARK).text(order.notes, 50, rowY + 26, { width: PAGE_W * 0.52 });
      }

      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      // FOOTER
      // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
      const footerY = doc.page.height - 85;
      doc.moveTo(50, footerY).lineTo(50 + PAGE_W, footerY).stroke(RULE);

      if (taxNotes) {
        doc.fillColor(MUTED).font('Helvetica').fontSize(7)
          .text(taxNotes, 50, footerY + 8, { width: PAGE_W * 0.65 });
      }

      doc.fillColor(MUTED).font('Helvetica-Oblique').fontSize(7)
        .text('This is a computer-generated proforma invoice and does not require a signature.',
          50, footerY + 24, { width: PAGE_W * 0.65 });

      // Generated on
      doc.fillColor('#9CA3AF').font('Helvetica').fontSize(6)
        .text(
          `Generated: ${new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })} IST`,
          50 + PAGE_W - 160, footerY + 8, { width: 160, align: 'right' },
        );

      doc.end();
    });
  }

  private toOrderPublicDto(order: Order) {
    return {
      id: order.id,
      orderNo: order.orderNo,
      status: order.status,
      items: order.items?.map((item) => ({
        id: item.id,
        productId: item.productId,
        sku: item.sku,
        name: item.name,
        qty: item.qty,
        dpPricePaise: item.dpPricePaise,
        lineTotalDpPaise: item.lineTotalDpPaise,
        imageUrl: item.product?.images?.[0] || null,
      })),
      subtotalDpPaise: order.subtotalDpPaise,
      discountAppliedPaise: order.discountAppliedPaise,
      courierFeePaise: order.courierFeePaise,
      shippingOverridePaise: order.shippingOverridePaise,
      taxPaise: order.taxPaise,
      grandTotalPaise: order.grandTotalPaise,
      addressSnapshot: order.addressSnapshot,
      estimatedDeliveryDate: order.estimatedDeliveryDate ? new Date(order.estimatedDeliveryDate).toISOString() : null,
      courier: order.courier,
      tracking: order.tracking,
      notes: order.notes,
      createdAt: order.createdAt ? new Date(order.createdAt).toISOString() : new Date().toISOString(),
      updatedAt: order.updatedAt ? new Date(order.updatedAt).toISOString() : new Date().toISOString(),
    };
  }
  async createOrderOnBehalf(dto: CreateOrderOnBehalfDto, adminId: string, ip?: string) {
    const user = await this.userRepository.findOne({
      where: { id: dto.userId }, // Use existing user
      relations: ['dealerTier'],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // validate and fetch products
    const itemsDto = dto.items;
    const productIds = itemsDto.map((item) => item.productId);
    const products = await this.productRepository.find({
      where: productIds.map((id) => ({ id })),
    });

    if (products.length !== productIds.length) {
      throw new AppException('INVALID_PRODUCTS', 'One or more products not found');
    }

    // Calculate totals
    let subtotalDpPaise = 0;
    const orderItems: Partial<OrderItem>[] = [];

    for (const itemDto of itemsDto) {
      const product = products.find((p) => p.id === itemDto.productId);
      if (!product) continue;

      const dpPricePaise = Math.round((Number(product.price) || 0) * 100);
      const lineTotalPaise = dpPricePaise * itemDto.qty;
      subtotalDpPaise += lineTotalPaise;

      orderItems.push({
        productId: product.id,
        sku: product.sku,
        name: product.name,
        qty: itemDto.qty,
        dpPricePaise: dpPricePaise,
        lineTotalDpPaise: lineTotalPaise,
        taxPercent: product.gstPercent,
      });
    }

    // Admin created orders might skip dealer discount logic or apply it?
    // Let's apply it if the user IS a dealer.
    let discountAppliedPaise = 0;
    if (user.role === UserRole.DEALER && user.dealerTier) {
      const discountPct = user.dealerTier.discountPct;
      discountAppliedPaise = Math.round((subtotalDpPaise * discountPct) / 100);
    }

    const subtotalAfterDiscountPaise = subtotalDpPaise - discountAppliedPaise;

    // Courier Fee - Use service or default 0 for admin pickup?
    // Let's assume standard calculation for now.
    const courierFeePaise = await this.courierService.calculateFee(subtotalAfterDiscountPaise);

    const taxableAmountPaise = subtotalAfterDiscountPaise + courierFeePaise;
    const avgTaxPercent = orderItems.reduce((sum, item) => sum + (item.taxPercent || 0), 0) / (orderItems.length || 1);
    const taxPaise = Math.round((taxableAmountPaise * avgTaxPercent) / 100);

    const grandTotalPaise = subtotalAfterDiscountPaise + courierFeePaise + taxPaise;

    const orderNo = await this.orderNumberService.generateOrderNo();

    // Use provided address or fallback to user's existing address
    let addressSnapshot: any = {};

    if (dto.address) {
      addressSnapshot = {
        ...dto.address,
        // Ensure name/phone are present, fallback to user defaults if not in address DTO (though DTO makes them available)
        name: dto.address.name || user.name,
        phone: dto.address.phone || user.phone,
      };

      // Update user profile if requested
      // Update user profile if requested
      if (dto.saveAddress) {
        /*
         Old legacy way - modifying JSON column
        user.address = {
          street: dto.address.street,
          city: dto.address.city,
          state: dto.address.state,
          zipCode: dto.address.zipCode,
          country: dto.address.country,
        };
        await this.userRepository.save(user);
        */

        // New way - using AddressesService
        await this.addressesService.create(user.id, {
          name: dto.address.name || user.name,
          phone: dto.address.phone || user.phone,
          street: dto.address.street,
          city: dto.address.city,
          state: dto.address.state,
          zipCode: dto.address.zipCode,
          // Use provided type or default to HOME
          type: (dto.address.type as AddressType) || AddressType.HOME,
          landmark: dto.address.landmark,
          label: dto.address.label,
          isDefault: false, // Don't override existing default unless specified
        });
      }
    } else {
      // Fallback to existing user address
      addressSnapshot = user.address
        ? { ...user.address, name: user.name, phone: user.phone }
        : {
          name: user.name,
          phone: user.phone,
          street: 'Admin Created',
          city: 'Unknown',
          state: 'Unknown',
          zipCode: '000000',
          country: 'India'
        };
    }

    const order = await this.dataSource.transaction(async (manager) => {
      const orderEntity = manager.create(Order, {
        orderNo,
        userId: user.id,
        status: OrderStatus.PENDING, // Directly pending
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
        addressSnapshot: addressSnapshot,
        notes: `Created by Admin`,
        paymentMethod: dto.paymentMethod || 'COD', // Use provided payment method
      });

      const savedOrder = await manager.save(Order, orderEntity);

      const itemsToSave = orderItems.map((item) =>
        manager.create(OrderItem, { ...item, orderId: savedOrder.id }),
      );
      await manager.save(OrderItem, itemsToSave);

      return savedOrder;
    });

    // Notify user via WhatsApp? Yes, good practice.
    // Fetch fresh to ensure relations for template if needed (though draft used orderWithItems)
    const orderWithItems = await this.orderRepository.findOne({
      where: { id: order.id },
      relations: ['items', 'items.product'],
    });

    // We can fire and forget notification
    this.whatsappService.sendOrderNotification(orderWithItems, user).catch(console.error);

    // In-App Notification (User)
    this.notificationsService.create(
      user.id,
      'Order Confirmed',
      `Your order #${orderWithItems.orderNo} has been successfully placed.`,
      NotificationType.ORDER_UPDATE,
      { orderId: orderWithItems.id }
    ).then(() => console.log(`Ã°Å¸â€â€ Notification sent to user ${user.id} for Order ${orderWithItems.orderNo}`))
      .catch(err => console.error('Failed to send user notification', err));

    this.auditLogsService.logAction(
      adminId,
      AuditLogActionType.ORDER,
      `Created Order ${orderWithItems.orderNo}`,
      `Created order on behalf of user`,
      ip
    ).catch(console.error);

    return {
      id: orderWithItems.id,
      orderNo: orderWithItems.orderNo,
      status: orderWithItems.status,
      grandTotalDisplay: `Ã¢â€šÂ¹${(grandTotalPaise / 100).toFixed(2)} `,
    };
  }

  async addItemToCart(userId: string, itemDto: { productId: string; qty: number }) {
    // 1. Get or Create Single Draft
    let draft = await this._getOrCreateSingleDraft(userId);

    // 2. Validate Product
    const product = await this.productRepository.findOne({ where: { id: itemDto.productId } });
    if (!product) {
      throw new AppException('INVALID_PRODUCT', 'Product not available');
    }

    // 3. Resolve dealer discount percentage (user.discountPercentage is the canonical source)
    const user = draft.user;
    const dealerDiscountPct =
      user?.role === UserRole.DEALER
        ? Number(user.discountPercentage || 0)
        : 0;

    // Unit price after dealer discount (baked-in, not a separate adjustment)
    let rawPricePaise    = Math.round((Number(product.price) || 0) * 100);
    
    // If the GLOBAL setting says prices include GST, extract the exclusive base price
    const globalGstInclusiveSetting = await this.settingsService.getSetting('system.price_includes_gst');
    const isInclusive = globalGstInclusiveSetting === 'true';
    if (isInclusive && (product.gstPercent || 0) > 0) {
      rawPricePaise = Math.round(rawPricePaise / (1 + product.gstPercent / 100));
    }

    const dpPricePaise     = dealerDiscountPct > 0
      ? Math.round(rawPricePaise * (1 - dealerDiscountPct / 100))
      : rawPricePaise;

    // 4. Check if Item exists in draft (HANDLE DUPLICATES)
    const existingItems = draft.items.filter(i => i.productId === itemDto.productId);

    await this.dataSource.transaction(async (manager) => {
      // 5. Update or Add Item (with deduplication)
      if (existingItems.length > 0) {
        const primaryItem = existingItems[0];
        let existingQtySum = 0;
        for (const item of existingItems) existingQtySum += item.qty;
        primaryItem.qty              = existingQtySum + itemDto.qty;
        primaryItem.dpPricePaise     = dpPricePaise;
        primaryItem.lineTotalDpPaise = dpPricePaise * primaryItem.qty;
        primaryItem.taxPercent       = product.gstPercent;
        await manager.save(OrderItem, primaryItem);
        if (existingItems.length > 1) {
          await manager.remove(existingItems.slice(1));
        }
      } else {
        const newItem = manager.create(OrderItem, {
          orderId:         draft.id,
          productId:       product.id,
          sku:             product.sku,
          name:            product.name,
          qty:             itemDto.qty,
          dpPricePaise:    dpPricePaise,
          lineTotalDpPaise: dpPricePaise * itemDto.qty,
          taxPercent:      product.gstPercent,
        });
        await manager.save(OrderItem, newItem);
      }

      // 6. Recalculate Totals
      const allItems = await manager.find(OrderItem, { where: { orderId: draft.id } });
      await this._recalculateOrderTotals(draft, allItems, manager);
    });

    // 7. Return updated draft
    return this.findOne(draft.id, userId, 'consumer');
  }

  async confirmOrder(userId: string, dto: ConfirmOrderDto) {
    console.log('Ã°Å¸Å¡â‚¬ CONFIRM_ORDER: Started for user:', userId);

    // 1. Get current draft
    const draft = await this._getOrCreateSingleDraft(userId);
    console.log('Ã°Å¸â€œÂ¦ CONFIRM_ORDER: Draft retrieved:', draft.id);

    if (draft.items.length === 0) {
      throw new BadRequestException('Cart is empty');
    }

    // 2. Enforce minimum order value (subtotal + tax, excluding shipping)
    try {
      const { minOrderValuePaise } = await this.settingsService.getCartSettings();
      const orderValuePaise = Number(draft.subtotalDpPaise) + Number(draft.taxPaise);
      if (minOrderValuePaise > 0 && orderValuePaise < minOrderValuePaise) {
        const shortfallRs = ((minOrderValuePaise - orderValuePaise) / 100).toFixed(2);
        const minRs = (minOrderValuePaise / 100).toFixed(2);
        throw new BadRequestException(
          `Minimum order value is Ã¢â€šÂ¹${minRs}. Add Ã¢â€šÂ¹${shortfallRs} more to place your order.`,
        );
      }
    } catch (e) {
      if (e instanceof BadRequestException) throw e;
      // Settings read failure Ã¢â‚¬â€ allow order to proceed
    }

    // 2. Update address, status, and payment method
    // Note: In a real app, we would validate payment here
    draft.addressSnapshot = dto.address;
    draft.paymentMethod = dto.paymentMethod;

    // Generate real order number now that it's being placed
    draft.orderNo = await this.orderNumberService.generateOrderNo();
    draft.status = OrderStatus.PENDING; // or CONFIRMED depending on flow
    console.log('Ã¢Å“â€¦ CONFIRM_ORDER: Status set to PENDING, orderNo:', draft.orderNo);

    // 4. Save
    await this.orderRepository.save(draft);

    // 5. Send notification
    const orderWithItems = await this.orderRepository.findOne({
      where: { id: draft.id },
      relations: ['items', 'items.product', 'user'],
    });
    console.log('Ã°Å¸â€˜Â¤ CONFIRM_ORDER: Loaded order with items, starting notifications...');

    // We can await or fire-and-forget
    try {
      await this.whatsappService.sendOrderNotification(orderWithItems, orderWithItems.user);
    } catch (e) {
      console.error('Ã¢Å¡Â Ã¯Â¸Â WARN: Failed to send WhatsApp notification:', e);
    }

    // In-App Notification (User)
    try {
      await this.notificationsService.create(
        userId,
        'Order Placed',
        `Your order #${draft.orderNo} has been placed successfully.`,
        NotificationType.ORDER_UPDATE,
        { orderId: draft.id }
      );
    } catch (e) {
      console.error('Ã¢Å¡Â Ã¯Â¸Â WARN: Failed to send User In-App notification:', e);
    }

    // In-App Notification (Admin)
    try {
      await this.notificationsService.notifyAdmins(
        'New Order Received',
        `User ${orderWithItems.user.name} placed order #${draft.orderNo}. Total: Ã¢â€šÂ¹${(draft.grandTotalPaise / 100).toFixed(2)}`,
        NotificationType.NEW_ORDER,
        { orderId: draft.id },
        userId // Exclude the user who placed the order
      );
    } catch (e) {
      console.error('Ã¢Å¡Â Ã¯Â¸Â WARN: Failed to send Admin In-App notification:', e);
    }

    return this.toOrderPublicDto(orderWithItems);
  }

  async removeItemFromCart(userId: string, productId: string) {
    // 1. Get Single Draft
    const draft = await this._getOrCreateSingleDraft(userId);

    // 2. Find ALL items with this productId (to handle duplicates)
    const itemsToRemove = draft.items.filter(i => i.productId === productId);
    if (itemsToRemove.length === 0) {
      // Item not in cart, just return current state
      return this.findOne(draft.id, userId, 'consumer');
    }

    await this.dataSource.transaction(async (manager) => {
      // Delete ALL items with this productId from this draft
      await manager.delete(OrderItem, {
        orderId: draft.id,
        productId: productId
      });

      // Also clean up any duplicate items across ALL drafts for this user
      const allDrafts = await manager.find(Order, {
        where: { userId, status: OrderStatus.DRAFT }
      });

      // Delete this product from all other drafts too
      for (const otherDraft of allDrafts) {
        if (otherDraft.id !== draft.id) {
          await manager.delete(OrderItem, {
            orderId: otherDraft.id,
            productId: productId
          });
        }
      }

      // 3. Recalculate Totals
      const remainingItems = await manager.find(OrderItem, { where: { orderId: draft.id } });

      if (remainingItems.length === 0) {
        // Empty cart -> update totals to 0 and clean up zombie drafts
        await this._recalculateOrderTotals(draft, remainingItems, manager);

        // Delete zombie drafts
        const zombies = allDrafts.filter(d => d.id !== draft.id);
        if (zombies.length > 0) {
          await manager.delete(OrderItem, { orderId: In(zombies.map(d => d.id)) });
          await manager.delete(Order, { id: In(zombies.map(d => d.id)) });
        }
      } else {
        await this._recalculateOrderTotals(draft, remainingItems, manager);
      }
    });

    return this.findOne(draft.id, userId, 'consumer');
  }

  async updateCartItem(userId: string, productId: string, qty: number) {
    if (qty <= 0) return this.removeItemFromCart(userId, productId);

    const draft   = await this._getOrCreateSingleDraft(userId);
    const item    = draft.items.find(i => i.productId === productId);
    if (!item) throw new NotFoundException('Item not found in cart');

    const product = await this.productRepository.findOne({ where: { id: productId } });

    // Resolve dealer discount
    const user = draft.user;
    const dealerDiscountPct =
      user?.role === UserRole.DEALER
        ? Number(user.discountPercentage || 0)
        : 0;
    let rawPricePaise = Math.round((Number(product.price) || 0) * 100);
    
    // If the GLOBAL setting says prices include GST, extract the exclusive base price
    const globalGstInclusiveSetting2 = await this.settingsService.getSetting('system.price_includes_gst');
    const isInclusive2 = globalGstInclusiveSetting2 === 'true';
    if (isInclusive2 && (product.gstPercent || 0) > 0) {
      rawPricePaise = Math.round(rawPricePaise / (1 + product.gstPercent / 100));
    }

    const dpPricePaise  = dealerDiscountPct > 0
      ? Math.round(rawPricePaise * (1 - dealerDiscountPct / 100))
      : rawPricePaise;

    await this.dataSource.transaction(async (manager) => {
      item.qty             = qty;
      item.dpPricePaise    = dpPricePaise;
      item.lineTotalDpPaise = dpPricePaise * qty;
      await manager.save(OrderItem, item);

      const allItems = await manager.find(OrderItem, { where: { orderId: draft.id } });
      await this._recalculateOrderTotals(draft, allItems, manager);
    });

    return this.findOne(draft.id, userId, 'consumer');
  }

  // --- Private Helpers ---

  /** Returns the user's current draft order (cart) without creating one. Returns null if no draft exists. */
  async getCurrentDraft(userId: string): Promise<any | null> {
    const draft = await this.orderRepository.findOne({
      where: { userId, status: OrderStatus.DRAFT },
      relations: ['items', 'items.product', 'user'],
      order: { updatedAt: 'DESC' },
    });
    if (!draft) return null;
    return this.toOrderPublicDto(draft);
  }

  private async _getOrCreateSingleDraft(userId: string): Promise<Order> {
    const allDrafts = await this.orderRepository.find({
      where: { userId, status: OrderStatus.DRAFT },
      relations: ['items', 'user', 'user.dealerTier'],
      order: { updatedAt: 'DESC' },
    });

    let masterDraft = allDrafts.length > 0 ? allDrafts[0] : null;

    // Cleanup zombies
    if (allDrafts.length > 1) {
      const zombies = allDrafts.slice(1);
      await this.dataSource.transaction(async (manager) => {
        for (const zombie of zombies) {
          await manager.delete(OrderItem, { orderId: zombie.id });
        }
        await manager.delete(Order, { id: In(zombies.map(z => z.id)) });
      });
    }

    if (!masterDraft) {
      const user = await this.userRepository.findOne({
        where: { id: userId }, relations: ['dealerTier']
      });
      // Store user.discountPercentage as canonical discount (not just dealerTier)
      const discountPct = user?.role === UserRole.DEALER
        ? Number(user.discountPercentage || user.dealerTier?.discountPct || 0)
        : 0;
      const orderNo = `DRAFT-${Date.now()}`;
      masterDraft = await this.orderRepository.save(
        this.orderRepository.create({
          userId,
          orderNo,
          status: OrderStatus.DRAFT,
          roleSnapshot: { role: user.role, dealerTierId: user.dealerTierId, discountPct },
          subtotalDpPaise: 0,
          grandTotalPaise: 0
        })
      );
      masterDraft.items = [];
      masterDraft.user  = user;
    } else {
      // Always refresh roleSnapshot.discountPct in case admin changed the user's discount
      const user = masterDraft.user;
      if (user?.role === UserRole.DEALER) {
        const freshDiscountPct = Number(user.discountPercentage || user.dealerTier?.discountPct || 0);
        if ((masterDraft.roleSnapshot?.discountPct ?? -1) !== freshDiscountPct) {
          masterDraft.roleSnapshot = {
            ...masterDraft.roleSnapshot,
            discountPct: freshDiscountPct,
          };
          await this.orderRepository.save(masterDraft);
        }
      }
    }

    return masterDraft;
  }

  private async _recalculateOrderTotals(order: Order, items: OrderItem[], manager: any) {
    // subtotal = sum of line totals â€” dealer discount is already baked into dpPricePaise
    let subtotalDpPaise = 0;
    for (const item of items) {
      subtotalDpPaise += Number(item.lineTotalDpPaise);
    }

    // No separate discount adjustment â€” the per-item price already reflects the dealer price.
    const discountAppliedPaise = 0;
    const subtotalAfterDiscount = subtotalDpPaise;

    const courierFeePaise = await this.courierService.calculateFee(subtotalAfterDiscount);
    const taxableAmount   = subtotalAfterDiscount + courierFeePaise;

    const avgTax = items.length > 0
      ? items.reduce((sum, i) => sum + Number(i.taxPercent), 0) / items.length
      : 0;

    const taxPaise       = Math.round((taxableAmount * avgTax) / 100);
    const grandTotalPaise = subtotalAfterDiscount + courierFeePaise + taxPaise;

    await manager.update(Order, { id: order.id }, {
      subtotalDpPaise,
      discountAppliedPaise,
      courierFeePaise,
      taxPaise,
      grandTotalPaise,
    });
  }

  private _returnEmptyCart() {
    return {
      id: null,
      orderNo: null,
      status: 'draft',
      items: [],
      subtotalDpPaise: 0,
      discountAppliedPaise: 0,
      courierFeePaise: 0,
      taxPaise: 0,
      grandTotalPaise: 0,
      whatsappLink: '',
      createdAt: new Date().toISOString()
    };
  }
  async getAbandonedCarts(hoursSinceUpdate: number, ignoreOlderThanHours: number = 72) {
    const cutoffDate = new Date();
    cutoffDate.setHours(cutoffDate.getHours() - hoursSinceUpdate);

    const ignoreDate = new Date();
    ignoreDate.setHours(ignoreDate.getHours() - ignoreOlderThanHours);

    // Find drafts updated BEFORE cutoff but AFTER ignoreDate
    // Only include carts that haven't been notified yet
    return this.orderRepository.createQueryBuilder('o')
      .leftJoinAndSelect('o.user', 'user')
      .leftJoinAndSelect('o.items', 'items')
      .leftJoinAndSelect('items.product', 'product')
      .where('o.status = :status', { status: OrderStatus.DRAFT })
      .andWhere('o.updatedAt < :cutoffDate', { cutoffDate })
      .andWhere('o.updatedAt > :ignoreDate', { ignoreDate })
      .andWhere('o.items IS NOT NULL') // Ensure it has items (handled by inner join logic usually but drafts might vary)
      .andWhere('o.abandonedCartNotificationSent = :notified', { notified: false }) // Only get un-notified carts
      .getMany();
  }

  async markAbandonedCartNotified(orderId: string) {
    return this.orderRepository.update(
      { id: orderId },
      { abandonedCartNotificationSent: true }
    );
  }

  async remove(id: string) {
    const order = await this.orderRepository.findOne({ where: { id } });
    if (!order) {
      throw new NotFoundException(`Order #${id} not found`);
    }
    return this.orderRepository.remove(order);
  }
}



