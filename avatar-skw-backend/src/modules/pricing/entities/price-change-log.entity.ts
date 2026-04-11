import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Product } from '../../products/entities/product.entity';
import { User } from '../../users/entities/user.entity';

@Entity('price_change_logs')
export class PriceChangeLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'product_id' })
  @Index()
  productId: string;

  @ManyToOne(() => Product)
  @JoinColumn({ name: 'product_id' })
  product: Product;

  @Column()
  @Index()
  sku: string;

  @Column({ name: 'old_dp_paise', type: 'bigint' })
  oldDpPaise: number;

  @Column({ name: 'new_dp_paise', type: 'bigint' })
  newDpPaise: number;

  @Column({ name: 'changed_by' })
  changedBy: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'changed_by' })
  changedByUser: User;

  @Column({ name: 'changed_at' })
  @Index()
  changedAt: Date;

  @Column({ type: 'text', nullable: true })
  notes: string;
}


