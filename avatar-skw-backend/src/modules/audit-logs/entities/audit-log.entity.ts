import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum AuditLogActionType {
    ORDER = 'ORDER',
    USER = 'USER',
    AUTH = 'AUTH',
    INVENTORY = 'INVENTORY',
    DELETE = 'DELETE',
    SETTINGS = 'SETTINGS',
    VIEW = 'VIEW',
}

export enum AuditLogStatus {
    SUCCESS = 'SUCCESS',
    WARNING = 'WARNING',
    ERROR = 'ERROR',
}

@Entity('audit_logs')
export class AuditLog {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'user_id', nullable: true })
    @Index()
    userId: string;

    @ManyToOne(() => User, { onDelete: 'SET NULL' })
    @JoinColumn({ name: 'user_id' })
    user: User;

    @Column({
        type: 'enum',
        enum: AuditLogActionType,
        name: 'action_type',
    })
    actionType: AuditLogActionType;

    @Column()
    title: string;

    @Column({ nullable: true })
    details: string;

    @Column({
        type: 'enum',
        enum: AuditLogStatus,
        default: AuditLogStatus.SUCCESS,
    })
    status: AuditLogStatus; // Success, Alert, Warning - maps to Badge Colors

    @Column({ name: 'entity_id', nullable: true })
    @Index()
    entityId: string;

    @Column({ name: 'entity_type', nullable: true })
    entityType: string;

    @Column({ name: 'ip_address', nullable: true })
    ipAddress: string;

    @Column({ name: 'device_info', nullable: true })
    deviceInfo: string;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;
}
