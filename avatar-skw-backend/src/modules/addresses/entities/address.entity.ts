import {
    Entity,
    Column,
    PrimaryGeneratedColumn,
    CreateDateColumn,
    UpdateDateColumn,
    ManyToOne,
    JoinColumn,
    Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum AddressType {
    HOME = 'home',
    WORK = 'work',
    OTHER = 'other',
}

@Entity('addresses')
export class Address {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'user_id' })
    @Index()
    userId: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'user_id' })
    user: User;

    @Column()
    name: string;

    @Column()
    street: string;

    @Column()
    city: string;

    @Column()
    state: string;

    @Column({ name: 'zip_code' })
    zipCode: string;

    @Column()
    phone: string;

    @Column({
        type: 'enum',
        enum: AddressType,
        default: AddressType.HOME,
    })
    type: AddressType;

    @Column({ name: 'is_default', default: false })
    isDefault: boolean;

    @Column({ nullable: true })
    landmark: string;

    @Column({ nullable: true })
    label: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
