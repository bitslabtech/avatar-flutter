import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    OneToMany,
    CreateDateColumn,
    UpdateDateColumn,
    JoinColumn,
} from 'typeorm';
import { Category } from './category.entity';
import { Brand } from '../../brands/entities/brand.entity';
import { Review } from '../../reviews/entities/review.entity';

@Entity('products')
export class Product {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ unique: true })
    sku: string;

    @Column({ name: 'variation_group_id', nullable: true })
    variationGroupId: string;

    @Column({ name: 'variation_type', nullable: true })
    variationType: string;

    @Column()
    name: string;

    @Column({ nullable: true })
    variant: string;

    @Column({ nullable: true })
    size: string;

    @Column('decimal', { precision: 10, scale: 2 })
    price: number;

    @Column('decimal', { precision: 10, scale: 2, nullable: true })
    mrp: number;

    @Column({ type: 'text', nullable: true })
    description: string;


    @Column({ default: 'INR' })
    currency: string;

    @Column({ nullable: true })
    hsn: string;

    @Column('int', { nullable: true })
    gstPercent: number;

    @Column({ name: 'is_gst_inclusive', default: false })
    isGstInclusive: boolean;

    @Column({ nullable: true })
    material: string;

    @Column({ default: true })
    isActive: boolean;

    @Column({ nullable: true })
    badge: string;

    @Column('simple-array', { nullable: true })
    images: string[];

    @Column('jsonb', { nullable: true })
    specifications: Record<string, any>;

    @ManyToOne(() => Brand, (brand) => brand.products, { nullable: true, onDelete: 'SET NULL' })
    @JoinColumn({ name: 'brandId' })
    brandRel: Brand;

    @Column({ nullable: true })
    brandId: string;

    @Column({ nullable: true })
    categoryId: string;

    @ManyToOne(() => Category, (category) => category.products, {
        nullable: true,
        onDelete: 'SET NULL',
    })
    @JoinColumn({ name: 'categoryId' })
    category: Category;

    @OneToMany(() => Review, (review) => review.product)
    reviews: Review[];

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
