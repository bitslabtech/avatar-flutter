import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Order } from './order.entity';
import { Product } from '../../products/entities/product.entity';

@Entity('order_items')
@Index(['orderId', 'productId'], { unique: true })
export class OrderItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id' })
  orderId: string;

  @ManyToOne(() => Order, (order) => order.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: Order;

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

  @Column({ name: 'image_url', nullable: true })
  imageUrl: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}


