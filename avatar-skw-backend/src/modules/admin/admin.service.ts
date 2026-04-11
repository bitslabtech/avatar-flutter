import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order, OrderStatus } from '../orders/entities/order.entity';
import { Quotation } from '../quotations/entities/quotation.entity';
import { CreateOrderDto } from '../orders/dto/orders.dto';
import { OrdersService } from '../orders/orders.service';
import { QuotationsService } from '../quotations/quotations.service';

import { User, UserRole } from '../users/entities/user.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
    @InjectRepository(Quotation)
    private quotationRepository: Repository<Quotation>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private ordersService: OrdersService,
    private quotationsService: QuotationsService,
  ) { }

  async getDashboard() {
    // 1. Order Status Counts & Revenue
    const orderStatsQuery = this.orderRepository
      .createQueryBuilder('order')
      .select('order.status', 'status')
      .addSelect('COUNT(*)', 'count')
      .addSelect('SUM(order.grand_total_paise)', 'revenue')
      .where('order.status IN (:...statuses)', {
        statuses: [OrderStatus.PENDING, OrderStatus.CONFIRMED, OrderStatus.DISPATCHED, OrderStatus.DELIVERED]
      })
      .groupBy('order.status')
      .getRawMany();

    // 2. User Role Counts
    const userStatsQuery = this.userRepository
      .createQueryBuilder('user')
      .select('user.role', 'role')
      .addSelect('COUNT(*)', 'count')
      .where('user.role IN (:...roles)', {
        roles: [UserRole.CONSUMER, UserRole.ADMIN]
      })
      .groupBy('user.role')
      .getRawMany();

    // 3. Orders per day for the last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const ordersPerDayQuery = this.orderRepository
      .createQueryBuilder('order')
      .select("DATE(order.createdAt)", 'date')
      .addSelect('COUNT(*)', 'count')
      .where('order.createdAt >= :date', { date: thirtyDaysAgo })
      .groupBy("DATE(order.createdAt)")
      .orderBy("DATE(order.createdAt)", 'ASC')
      .getRawMany();

    // Execute concurrently
    const [orderStats, userStats, ordersPerDay] = await Promise.all([
      orderStatsQuery,
      userStatsQuery,
      ordersPerDayQuery
    ]);

    // Aggregate Order Stats
    let pendingCount = 0;
    let totalOrders = 0;
    let totalSales = 0; // In paise

    orderStats.forEach(stat => {
      const count = parseInt(stat.count, 10) || 0;
      const revenue = parseInt(stat.revenue, 10) || 0;
      
      totalOrders += count;
      totalSales += revenue;
      
      if (stat.status === OrderStatus.PENDING) {
        pendingCount += count;
      }
    });

    // Aggregate User Stats
    let totalUsers = 0;
    let totalAdmins = 0;

    userStats.forEach(stat => {
      const count = parseInt(stat.count, 10) || 0;
      if (stat.role === UserRole.CONSUMER) totalUsers += count;
      if (stat.role === UserRole.ADMIN) totalAdmins += count;
    });

    return {
      pendingCount,
      totalOrders,
      totalUsers,
      totalAdmins,
      totalSales,
      ordersPerDay: ordersPerDay.map((row) => ({
        date: row.date,
        count: parseInt(row.count, 10),
      })),
    };
  }

  async createOrderOnBehalf(userId: string, createDto: CreateOrderDto) {
    return this.ordersService.createOrderDraft(userId, createDto);
  }

  async createQuotationOnBehalf(userId: string, createDto: CreateOrderDto) {
    return this.quotationsService.createQuotation(userId, createDto);
  }
}


