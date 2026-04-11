import {
    Entity,
    Column,
    PrimaryGeneratedColumn,
    CreateDateColumn,
    ManyToOne,
    JoinColumn,
    Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum NotificationType {
    ORDER_UPDATE = 'order_update',
    ACCOUNT_UPDATE = 'account_update',
    SYSTEM_ALERT = 'system_alert',
    PROMOTION = 'promotion',
    CART_REMINDER = 'cart_reminder',
    NEW_ORDER = 'new_order', // For Admin
    NEW_DEALER = 'new_dealer', // For Admin
    NEW_USER = 'new_user', // For Admin
}

@Entity('notifications')
export class Notification {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'user_id' })
    userId: string;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'user_id' })
    user: User;

    @Column()
    title: string;

    @Column()
    body: string;

    @Column({
        type: 'enum',
        enum: NotificationType,
        default: NotificationType.ORDER_UPDATE,
    })
    type: NotificationType;

    @Column({ type: 'jsonb', nullable: true })
    data: any; // Flexible payload for navigation (e.g., { orderId: '...' })

    @Column({ name: 'is_read', default: false })
    isRead: boolean;

    @CreateDateColumn({ name: 'created_at' })
    @Index()
    createdAt: Date;
}
