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
        dpSubtotalDisplay: '₹0.00',
        courierDisplay: '₹0.00',
        approxTotalDisplay: '₹0.00',
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

    // Single GROUP BY query — replaces 6 separate COUNT queries.
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
    console.log('🔧 SERVICE - updateStatus called with:', { id, updateDto });
    const order = await this.orderRepository.findOne({
      where: { id },
      relations: ['user']
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    console.log('🔧 SERVICE - Current order state:', {
      id: order.id,
      currentEstDate: order.estimatedDeliveryDate,
      currentCourier: order.courier,
      currentTracking: order.tracking
    });

    // Modify entity directly
    order.status = updateDto.status as OrderStatus;

    if (updateDto.estimatedDeliveryDate) {
      const dateObj = new Date(updateDto.estimatedDeliveryDate);
      console.log('🔧 SERVICE - Processing date:', {
        input: updateDto.estimatedDeliveryDate,
        dateObj: dateObj,
        dateObjString: dateObj.toString(),
        isValid: !isNaN(dateObj.getTime())
      });
      order.estimatedDeliveryDate = dateObj;
    }

    if (updateDto.courierProvider) {
      console.log('🔧 SERVICE - Updating courier:', updateDto.courierProvider);
      order.courier = {
        ...(order.courier || {}),
        provider: updateDto.courierProvider,
      };
    }

    if (updateDto.trackingNumber) {
      console.log('🔧 SERVICE - Updating tracking:', updateDto.trackingNumber);
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

    console.log('🔧 SERVICE - Entity before save:', {
      status: order.status,
      estimatedDeliveryDate: order.estimatedDeliveryDate,
      courier: order.courier,
      tracking: order.tracking
    });

    const saved = await this.orderRepository.save(order);
    console.log('✅ SERVICE - Save executed successfully');

    console.log('🔧 SERVICE - Saved result:', {
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
    console.log('🔍 SERVICE - Raw DB verification:', raw[0]);

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
    // TODO: Implement PDF generation
    throw new BadRequestException('PDF generation not yet implemented');
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
    ).then(() => console.log(`🔔 Notification sent to user ${user.id} for Order ${orderWithItems.orderNo}`))
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
      grandTotalDisplay: `₹${(grandTotalPaise / 100).toFixed(2)} `,
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

    // 3. Check if Item exists in draft (HANDLE DUPLICATES)
    const existingItems = draft.items.filter(i => i.productId === itemDto.productId);

    await this.dataSource.transaction(async (manager) => {
      // 4. Update or Add Item (with deduplication)
      if (existingItems.length > 0) {
        // Merge duplicates if any
        const primaryItem = existingItems[0];

        // Calculate total existing quantity from all duplicates
        let existingQtySum = 0;
        for (const item of existingItems) {
          existingQtySum += item.qty;
        }

        // Add new quantity to existing sum
        primaryItem.qty = existingQtySum + itemDto.qty;

        primaryItem.dpPricePaise = Math.round((Number(product.price) || 0) * 100);
        primaryItem.lineTotalDpPaise = primaryItem.dpPricePaise * primaryItem.qty;
        primaryItem.taxPercent = product.gstPercent;

        await manager.save(OrderItem, primaryItem);

        // Delete duplicates (slice(1) skips the primary item)
        if (existingItems.length > 1) {
          const duplicatesToRemove = existingItems.slice(1);
          await manager.remove(duplicatesToRemove);
        }
      } else {
        const dpPricePaise = Math.round((Number(product.price) || 0) * 100);
        const newItem = manager.create(OrderItem, {
          orderId: draft.id,
          productId: product.id,
          sku: product.sku,
          name: product.name,
          qty: itemDto.qty,
          dpPricePaise: dpPricePaise,
          lineTotalDpPaise: dpPricePaise * itemDto.qty,
          taxPercent: product.gstPercent,
        });
        await manager.save(OrderItem, newItem);
      }

      // 5. Recalculate Totals (This updates the Order entity)
      // We need to reload items to get the full list including the new one
      const allItems = await manager.find(OrderItem, { where: { orderId: draft.id } });
      await this._recalculateOrderTotals(draft, allItems, manager);
    });

    // 6. Return updated draft
    return this.findOne(draft.id, userId, 'consumer');
  }

  async confirmOrder(userId: string, dto: ConfirmOrderDto) {
    console.log('🚀 CONFIRM_ORDER: Started for user:', userId);

    // 1. Get current draft
    const draft = await this._getOrCreateSingleDraft(userId);
    console.log('📦 CONFIRM_ORDER: Draft retrieved:', draft.id);

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
          `Minimum order value is ₹${minRs}. Add ₹${shortfallRs} more to place your order.`,
        );
      }
    } catch (e) {
      if (e instanceof BadRequestException) throw e;
      // Settings read failure — allow order to proceed
    }

    // 2. Update address, status, and payment method
    // Note: In a real app, we would validate payment here
    draft.addressSnapshot = dto.address;
    draft.paymentMethod = dto.paymentMethod;

    // Generate real order number now that it's being placed
    draft.orderNo = await this.orderNumberService.generateOrderNo();
    draft.status = OrderStatus.PENDING; // or CONFIRMED depending on flow
    console.log('✅ CONFIRM_ORDER: Status set to PENDING, orderNo:', draft.orderNo);

    // 4. Save
    await this.orderRepository.save(draft);

    // 5. Send notification
    const orderWithItems = await this.orderRepository.findOne({
      where: { id: draft.id },
      relations: ['items', 'items.product', 'user'],
    });
    console.log('👤 CONFIRM_ORDER: Loaded order with items, starting notifications...');

    // We can await or fire-and-forget
    try {
      await this.whatsappService.sendOrderNotification(orderWithItems, orderWithItems.user);
    } catch (e) {
      console.error('⚠️ WARN: Failed to send WhatsApp notification:', e);
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
      console.error('⚠️ WARN: Failed to send User In-App notification:', e);
    }

    // In-App Notification (Admin)
    try {
      await this.notificationsService.notifyAdmins(
        'New Order Received',
        `User ${orderWithItems.user.name} placed order #${draft.orderNo}. Total: ₹${(draft.grandTotalPaise / 100).toFixed(2)}`,
        NotificationType.NEW_ORDER,
        { orderId: draft.id },
        userId // Exclude the user who placed the order
      );
    } catch (e) {
      console.error('⚠️ WARN: Failed to send Admin In-App notification:', e);
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

    const draft = await this._getOrCreateSingleDraft(userId);
    const item = draft.items.find(i => i.productId === productId);

    if (!item) throw new NotFoundException('Item not found in cart');

    const product = await this.productRepository.findOne({ where: { id: productId } });

    await this.dataSource.transaction(async (manager) => {
      item.qty = qty;
      const dpPricePaise = Math.round((Number(product.price) || 0) * 100);
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

    // Cleanup zombies and merge their items into master
    if (allDrafts.length > 1) {
      const zombies = allDrafts.slice(1);

      // If we have zombie drafts, delete all their items first to prevent orphans
      await this.dataSource.transaction(async (manager) => {
        for (const zombie of zombies) {
          // Delete all items from zombie drafts
          await manager.delete(OrderItem, { orderId: zombie.id });
        }
        // Delete the zombie draft orders
        await manager.delete(Order, { id: In(zombies.map(z => z.id)) });
      });
    }

    if (!masterDraft) {
      // Create new draft
      const user = await this.userRepository.findOne({
        where: { id: userId }, relations: ['dealerTier']
      });
      const orderNo = `DRAFT-${Date.now()}`;
      masterDraft = await this.orderRepository.save(
        this.orderRepository.create({
          userId,
          orderNo,
          status: OrderStatus.DRAFT,
          roleSnapshot: { role: user.role, dealerTierId: user.dealerTierId, discountPct: user.dealerTier?.discountPct },
          subtotalDpPaise: 0,
          grandTotalPaise: 0
        })
      );
      masterDraft.items = [];
      // Re-assign user for calculations
      masterDraft.user = user;
    }

    return masterDraft;
  }

  private async _recalculateOrderTotals(order: Order, items: OrderItem[], manager: any) {
    let subtotalDpPaise = 0;
    for (const item of items) {
      subtotalDpPaise += Number(item.lineTotalDpPaise);
    }

    // Apply discount
    let discountAppliedPaise = 0;
    // We need user context. If order.user is loaded.
    // If not loaded, we might need to fetch it? 
    // Assuming roleSnapshot has discountPct
    const discountPct = order.roleSnapshot?.discountPct || 0;
    discountAppliedPaise = Math.round((subtotalDpPaise * discountPct) / 100);

    const subtotalAfterDiscount = subtotalDpPaise - discountAppliedPaise;
    const courierFeePaise = await this.courierService.calculateFee(subtotalAfterDiscount);
    const taxableAmount = subtotalAfterDiscount + courierFeePaise;

    const avgTax = items.length > 0
      ? items.reduce((sum, i) => sum + Number(i.taxPercent), 0) / items.length
      : 0;

    const taxPaise = Math.round((taxableAmount * avgTax) / 100);
    const grandTotalPaise = subtotalAfterDiscount + courierFeePaise + taxPaise;

    // Update Order
    await manager.update(Order, { id: order.id }, {
      subtotalDpPaise,
      discountAppliedPaise,
      courierFeePaise,
      taxPaise,
      grandTotalPaise
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


