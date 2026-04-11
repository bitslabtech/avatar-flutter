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
import { User } from '../../users/entities/user.entity';
import { QuotationItem } from './quotation-item.entity';

export enum QuotationStatus {
  DRAFT = 'draft',
  SENT = 'sent',
  ACCEPTED = 'accepted',
  REJECTED = 'rejected',
  EXPIRED = 'expired',
}

@Entity('quotations')
export class Quotation {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'quotation_no', unique: true })
  @Index()
  quotationNo: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({
    type: 'enum',
    enum: QuotationStatus,
    default: QuotationStatus.DRAFT,
  })
  status: QuotationStatus;

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

  @Column({ name: 'tax_paise', type: 'bigint', default: 0 })
  taxPaise: number;

  @Column({ name: 'grand_total_paise', type: 'bigint' })
  grandTotalPaise: number;

  @Column({ type: 'jsonb', nullable: true })
  courier: {
    provider?: string;
    estimatedDays?: number;
  };

  @Column({ name: 'address_snapshot', type: 'jsonb' })
  addressSnapshot: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
    name?: string;
    phone?: string;
  };

  @OneToMany(() => QuotationItem, (item) => item.quotation, { cascade: true })
  items: QuotationItem[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}


