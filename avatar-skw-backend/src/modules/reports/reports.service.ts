import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, LessThanOrEqual, MoreThanOrEqual } from 'typeorm';
import { Order, OrderStatus } from '../orders/entities/order.entity';
import { GetReportsDto } from './dto/reports.dto';
import * as ExcelJS from 'exceljs';

@Injectable()
export class ReportsService {
    constructor(
        @InjectRepository(Order)
        private orderRepository: Repository<Order>,
    ) { }

    private getReportQuery(query: GetReportsDto, includeSort: boolean = true) {
        const qb = this.orderRepository.createQueryBuilder('order')
            .leftJoinAndSelect('order.user', 'user')
            .leftJoinAndSelect('user.dealerTier', 'dealerTier'); // If needed for dealer details

        if (includeSort) {
            qb.orderBy('order.createdAt', 'DESC');
        }

        // Filter by Date Range
        if (query.startDate && query.endDate) {
            qb.andWhere('order.createdAt BETWEEN :start AND :end', {
                start: new Date(query.startDate).toISOString(),
                end: new Date(query.endDate).toISOString()
            });
        } else if (query.startDate) {
            qb.andWhere('order.createdAt >= :start', { start: new Date(query.startDate).toISOString() });
        } else if (query.endDate) {
            qb.andWhere('order.createdAt <= :end', { end: new Date(query.endDate).toISOString() });
        }

        // Filter by User Role (Dealer vs Consumer)
        if (query.userType) {
            qb.andWhere('user.role = :role', { role: query.userType });
        }

        // Filter by Specific User ID
        if (query.userId) {
            qb.andWhere('order.userId = :userId', { userId: query.userId });
        }

        // Filter by Dealer ID (if specific dealer selected)
        if (query.dealerId) {
            qb.andWhere('user.id = :dealerId', { dealerId: query.dealerId });
        }

        // Search by User Name, Email, or Order Number
        if (query.search) {
            qb.andWhere(
                '(user.name ILIKE :search OR user.email ILIKE :search OR order.orderNo ILIKE :search)',
                { search: `%${query.search}%` }
            );
        }

        // Exclude Drafts usually, unless specifically wanted. Usually reports are for confirmed sales.
        // Let's exclude cancelled and drafts for "Sales" reports, or keep them but label them?
        // User asked for "Sales are recorded". Usually implies validated orders.
        // Let's include everything but Drafts.
        qb.andWhere('order.status != :draftStatus', { draftStatus: OrderStatus.DRAFT });

        // Also likely exclude Cancelled? Detailed reports usually include them but "Sales Revenue" excludes them.
        // For the list view, we show all. For aggregation, we might filter.

        return qb;
    }

    async getSalesReports(query: GetReportsDto) {
        const page = query.page || 1;
        const limit = query.limit || 10;
        const skip = (page - 1) * limit;

        const qb = this.getReportQuery(query);

        // Get simplified count and items
        const [orders, total] = await qb
            .skip(skip)
            .take(limit)
            .getManyAndCount();

        // Aggregations (separate query to avoid pagination limits affecting totals)
        const aggQb = this.getReportQuery(query, false);
        const totalRevenueResult = await aggQb
            .andWhere('order.status = :deliveredStatus', { deliveredStatus: OrderStatus.DELIVERED }) // Revenue usually only counts delivered/completed
            .select('SUM(order.grandTotalPaise)', 'total')
            .getRawOne();

        const totalOrdersCount = total; // This includes pending/cancelled etc from the filter

        // Calculate total sales (regardless of status, or maybe just valid ones?)
        // Let's show "Total Revenue" as Delivered/Shipped orders amount.
        // And "Total Order Value" as all orders.

        const totalRevenue = totalRevenueResult && totalRevenueResult.total ? parseInt(totalRevenueResult.total) / 100 : 0;

        return {
            data: orders,
            meta: {
                total,
                page,
                limit,
                totalPages: Math.ceil(total / limit),
            },
            summary: {
                totalOrders: total,
                totalRevenue: totalRevenue,
            }
        };
    }

    async exportSalesReports(query: GetReportsDto): Promise<Buffer> {
        const qb = this.getReportQuery(query);
        const orders = await qb.getMany(); // Get ALL matching records

        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Sales Report');

        // Define Columns
        worksheet.columns = [
            { header: 'Order No', key: 'orderNo', width: 20 },
            { header: 'Date', key: 'date', width: 20 },
            { header: 'Customer Name', key: 'customerName', width: 25 },
            { header: 'Customer Email', key: 'customerEmail', width: 30 },
            { header: 'Role', key: 'role', width: 15 },
            { header: 'Status', key: 'status', width: 15 },
            { header: 'Amount (₹)', key: 'amount', width: 15 },
        ];

        // Style Header
        worksheet.getRow(1).font = { bold: true };
        worksheet.getRow(1).fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FFE0E0E0' },
        };

        // Add Rows
        orders.forEach(order => {
            worksheet.addRow({
                orderNo: order.orderNo,
                date: new Date(order.createdAt).toLocaleDateString(),
                customerName: order.user?.name || 'Unknown',
                customerEmail: order.user?.email || 'N/A',
                role: order.user?.role || 'N/A',
                status: order.status,
                amount: (order.grandTotalPaise / 100).toFixed(2),
            });
        });

        // Generate Buffer
        const buffer = await workbook.xlsx.writeBuffer();
        return buffer as unknown as Buffer;
    }
}
