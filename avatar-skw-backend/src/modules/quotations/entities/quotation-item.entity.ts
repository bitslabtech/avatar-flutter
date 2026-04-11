import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Quotation } from './quotation.entity';
import { Product } from '../../products/entities/product.entity';

@Entity('quotation_items')
export class QuotationItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'quotation_id' })
  quotationId: string;

  @ManyToOne(() => Quotation, (quotation) => quotation.items, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'quotation_id' })
  quotation: Quotation;

  @Column({ name: 'product_id' })
  productId: string;

  @ManyToOne(() => Product)
  @JoinColumn({ name: 'product_id' })
  product: Product;

  @Column()
  sku: string;

  @Column()
  name: string;

  @Column({ type: 'int' })
  qty: number;

  @Column({ name: 'dp_price_paise', type: 'bigint' })
  dpPricePaise: number;

  @Column({ name: 'line_total_dp_paise', type: 'bigint' })
  lineTotalDpPaise: number;

  @Column({ name: 'tax_percent', type: 'decimal', precision: 5, scale: 2 })
  taxPercent: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}


