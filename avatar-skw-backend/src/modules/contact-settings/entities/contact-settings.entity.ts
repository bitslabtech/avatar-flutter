import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('contact_settings')
export class ContactSettings {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ type: 'varchar', length: 255, nullable: true })
    supportEmail: string;

    @Column({ type: 'varchar', length: 20, nullable: true })
    whatsappNumber: string;

    @Column({ type: 'varchar', length: 20, nullable: true })
    callNumber: string;

    @Column({ type: 'boolean', default: true })
    isActive: boolean;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
