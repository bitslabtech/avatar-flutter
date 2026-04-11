import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Order } from './entities/order.entity';
import { Quotation } from '../quotations/entities/quotation.entity';

@Injectable()
export class OrderNumberService {
  constructor(
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
    private dataSource: DataSource,
  ) {}

  /**
   * Generate unique order number in format: AVT-YYYYMMDD-XXXX
   * Uses per-day incremental counter stored in database (transaction-safe)
   */
  async generateOrderNo(): Promise<string> {
    const today = new Date();
    const datePrefix = today.toISOString().slice(0, 10).replace(/-/g, '');
    const prefix = `AVT-${datePrefix}-`;

    return this.dataSource.transaction(async (manager) => {
      // Find the last order number for today
      const lastOrder = await manager
        .createQueryBuilder(Order, 'order')
        .where('order.orderNo LIKE :prefix', { prefix: `${prefix}%` })
        .orderBy('order.orderNo', 'DESC')
        .getOne();

      let sequence = 1;
      if (lastOrder) {
        const lastSequence = parseInt(
          lastOrder.orderNo.slice(prefix.length),
          10,
        );
        sequence = lastSequence + 1;
      }

      const orderNo = `${prefix}${sequence.toString().padStart(4, '0')}`;

      // Verify uniqueness (should not happen, but safety check)
      const exists = await manager.findOne(Order, {
        where: { orderNo },
      });

      if (exists) {
        // Retry with incremented sequence
        sequence++;
        return `${prefix}${sequence.toString().padStart(4, '0')}`;
      }

      return orderNo;
    });
  }

  /**
   * Generate unique quotation number in format: QTN-YYYYMMDD-XXXX
   */
  async generateQuotationNo(): Promise<string> {
    const today = new Date();
    const datePrefix = today.toISOString().slice(0, 10).replace(/-/g, '');
    const prefix = `QTN-${datePrefix}-`;

    return this.dataSource.transaction(async (manager) => {
      const quotationRepo = manager.getRepository(Quotation);
      const lastQuotation = await quotationRepo
        .createQueryBuilder('quotation')
        .where('quotation.quotationNo LIKE :prefix', { prefix: `${prefix}%` })
        .orderBy('quotation.quotationNo', 'DESC')
        .getOne();

      let sequence = 1;
      if (lastQuotation) {
        const lastSequence = parseInt(
          lastQuotation.quotationNo.slice(prefix.length),
          10,
        );
        sequence = lastSequence + 1;
      }

      const quotationNo = `${prefix}${sequence.toString().padStart(4, '0')}`;

      const exists = await quotationRepo.findOne({
        where: { quotationNo },
      });

      if (exists) {
        sequence++;
        return `${prefix}${sequence.toString().padStart(4, '0')}`;
      }

      return quotationNo;
    });
  }
}

