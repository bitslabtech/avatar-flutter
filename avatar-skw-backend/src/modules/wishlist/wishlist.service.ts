
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Wishlist } from './entities/wishlist.entity';
import { User } from '../users/entities/user.entity';
import { Product } from '../products/entities/product.entity';

@Injectable()
export class WishlistService {
    constructor(
        @InjectRepository(Wishlist)
        private wishlistRepository: Repository<Wishlist>,
    ) { }

    async toggle(user: User, productId: string): Promise<{ status: 'added' | 'removed' }> {
        try {
            const existing = await this.wishlistRepository.findOne({
                where: {
                    user: { id: user.id },
                    product: { id: productId },
                },
            });

            if (existing) {
                await this.wishlistRepository.remove(existing);
                return { status: 'removed' };
            } else {
                const wishlist = this.wishlistRepository.create({
                    user: { id: user.id } as User,
                    product: { id: productId } as Product,
                });
                await this.wishlistRepository.save(wishlist);
                return { status: 'added' };
            }
        } catch (error) {
            console.error('Wishlist Toggle Error:', error);
            // Handle unique constraint violation (race condition)
            if (error.code === '23505') { // Postgres unique violation code
                return { status: 'added' }; // Assume it was added by parallel request
            }
            throw error;
        }
    }

    async findAll(user: User) {
        return this.wishlistRepository.find({
            where: { user: { id: user.id } },
            order: { createdAt: 'DESC' },
        });
    }

    async checkStatus(user: User, productId: string): Promise<{ isWishlisted: boolean }> {
        const count = await this.wishlistRepository.count({
            where: {
                user: { id: user.id },
                product: { id: productId },
            },
        });
        return { isWishlisted: count > 0 };
    }
}
