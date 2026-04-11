import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('banners')
export class Banner {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ nullable: true })
    title: string;

    @Column()
    imageUrl: string;

    @Column({ nullable: true })
    linkUrl: string;

    @Column({ nullable: true })
    tag: string;

    @Column({ nullable: true })
    description: string;

    @Column({ nullable: true })
    btnText: string;


    @Column({ type: 'int', default: 0 })
    order: number;

    @Column({ default: true })
    isActive: boolean;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
