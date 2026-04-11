
import { Entity, PrimaryGeneratedColumn, ManyToOne, JoinColumn, CreateDateColumn, Unique } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Product } from '../../products/entities/product.entity';

@Entity('wishlists')
@Unique(['user', 'product']) // Prevent duplicate saves of same product
export class Wishlist {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => User, (user) => user.wishlists, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'userId' })
    user: User;

    @ManyToOne(() => Product, { onDelete: 'CASCADE', eager: true }) // Eager load product details
    @JoinColumn({ name: 'productId' })
    product: Product;

    @CreateDateColumn()
    createdAt: Date;
}
