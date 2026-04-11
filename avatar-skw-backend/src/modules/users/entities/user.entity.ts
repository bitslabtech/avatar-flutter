import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
  OneToMany,
} from 'typeorm';
import { DealerTier } from './dealer-tier.entity';
import { Wishlist } from '../../wishlist/entities/wishlist.entity';

export enum UserRole {
  CONSUMER = 'consumer',
  DEALER = 'dealer',
  ADMIN = 'admin',
  SUPER_ADMIN = 'super_admin',
}

export enum UserStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  DELETED = 'deleted',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  @Index()
  phone: string;

  @Column({ nullable: true })
  email: string;

  @Column({ name: 'password_hash' })
  passwordHash: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.CONSUMER,
  })
  role: UserRole;

  @Column({
    type: 'enum',
    enum: UserStatus,
    default: UserStatus.PENDING,
  })
  status: UserStatus;

  @Column({ name: 'is_two_factor_enabled', default: false })
  isTwoFactorEnabled: boolean;

  // Company data for dealers
  @Column({ name: 'company_name', nullable: true })
  companyName: string;

  @Column({ name: 'discount_percentage', type: 'decimal', precision: 5, scale: 2, nullable: true, default: 0 })
  discountPercentage: number;

  @Column({ name: 'gst_vat', nullable: true, unique: true })
  gstVat: string;

  @Column({ type: 'jsonb', nullable: true })
  address: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
  };

  @Column({ name: 'dealer_tier_id', nullable: true })
  dealerTierId: string;

  @ManyToOne(() => DealerTier, { nullable: true })
  @JoinColumn({ name: 'dealer_tier_id' })
  dealerTier: DealerTier;

  @Column({ type: 'jsonb', nullable: true })
  documents: string[];

  @Column({ name: 'reset_otp', nullable: true, select: false })
  resetOtp: string;

  @Column({ name: 'reset_otp_expiry', nullable: true })
  resetOtpExpiry: Date;

  // JSONB column for Granular Admin Permissions
  // Structure: { "orders": ["read", "update"], "products": ["read", "delete"] }
  @Column({ type: 'jsonb', nullable: true })
  permissions: Record<string, string[]>;

  @Column({ nullable: true })
  avatar: string;

  @OneToMany(() => Wishlist, (wishlist) => wishlist.user)
  wishlists: Wishlist[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}


