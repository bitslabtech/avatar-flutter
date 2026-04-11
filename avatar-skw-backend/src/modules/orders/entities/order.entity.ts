import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  Index,
} from 'typeorm';
import { Transform } from 'class-transformer';
import { User } from '../../users/entities/user.entity';
import { OrderItem } from './order-item.entity';

export enum OrderStatus {
  DRAFT = 'draft',
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  DISPATCHED = 'dispatched',
  DELIVERED = 'delivered',
  CANCELLED = 'cancelled',
}

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_no', unique: true })
  @Index()
  orderNo: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({
    type: 'enum',
    enum: OrderStatus,
    default: OrderStatus.DRAFT,
  })
  status: OrderStatus;

  @Column({ name: 'role_snapshot', type: 'jsonb' })
  roleSnapshot: {
    role: string;
    dealerTierId?: string;
    discountPct?: number;
  };

  // All totals in paise
  @Column({ name: 'subtotal_dp_paise', type: 'bigint' })
  subtotalDpPaise: number;

  @Column({ name: 'discount_applied_paise', type: 'bigint', default: 0 })
  discountAppliedPaise: number;

  @Column({ name: 'courier_fee_paise', type: 'bigint', default: 0 })
  courierFeePaise: number;

  @Column({ name: 'shipping_override_paise', type: 'bigint', nullable: true, default: null })
  shippingOverridePaise: number | null;

  @Column({ name: 'tax_paise', type: 'bigint', default: 0 })
  taxPaise: number;

  @Column({ name: 'grand_total_paise', type: 'bigint' })
  grandTotalPaise: number;

  @Column({ type: 'jsonb', nullable: true })
  courier: {
    provider?: string;
    estimatedDays?: number;
  };

  @Column({ type: 'jsonb', nullable: true })
  tracking: {
    trackingNumber?: string;
    trackingUrl?: string;
  };

  @Column({ name: 'address_snapshot', type: 'jsonb', nullable: true })
  addressSnapshot: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
    name?: string;
    phone?: string;
  };

  @Column({ type: 'timestamp', nullable: true, name: 'estimated_delivery_date' })
  @Transform(({ value }) => value instanceof Date && !isNaN(value.getTime()) ? value.toISOString() : null, { toPlainOnly: true })
  estimatedDeliveryDate: Date;

  @Column({ name: 'payment_method', type: 'varchar', length: 50, nullable: true })
  paymentMethod: string;

  @Column({ type: 'text', nullable: true })
  notes: string;

  @Column({ name: 'abandoned_cart_notification_sent', type: 'boolean', default: false })
  abandonedCartNotificationSent: boolean;

  @OneToMany(() => OrderItem, (item) => item.order, { cascade: true })
  items: OrderItem[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}


