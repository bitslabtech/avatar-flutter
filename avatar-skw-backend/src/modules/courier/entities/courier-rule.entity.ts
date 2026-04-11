import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum CourierRuleType {
  FLAT = 'flat',
  VALUE_SLAB = 'value_slab',
  WEIGHT_SLAB = 'weight_slab',
}

@Entity('courier_rules')
export class CourierRule {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'enum',
    enum: CourierRuleType,
  })
  ruleType: CourierRuleType;

  @Column({ type: 'jsonb' })
  ranges: Array<{
    min?: number;
    max?: number;
    feePaise: number;
  }>;

  @Column({ name: 'flat_fee_paise', type: 'bigint', nullable: true })
  flatFeePaise: number;

  @Column({ type: 'int', default: 0 })
  priority: number; // Lower number = higher priority

  @Column({ default: true })
  active: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}


