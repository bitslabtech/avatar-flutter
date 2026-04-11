import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review } from './entities/review.entity';
import { CreateReviewDto } from './dto/create-review.dto';
import { User } from '../users/entities/user.entity';

@Injectable()
export class ReviewsService {
    constructor(
        @InjectRepository(Review)
        private reviewRepository: Repository<Review>,
    ) { }

    async create(createReviewDto: CreateReviewDto, user: User) {
        // Check if user already reviewed this product? (Optional: business rule)

        const review = this.reviewRepository.create({
            ...createReviewDto,
            userId: user.id,
        });

        return this.reviewRepository.save(review);
    }

    async findByProduct(productId: string) {
        const reviews = await this.reviewRepository.createQueryBuilder('review')
            .leftJoin('review.user', 'user')
            .addSelect(['user.id', 'user.name'])
            .where('review.productId = :productId', { productId })
            .andWhere('review.isActive = :isActive', { isActive: true })
            .orderBy('review.createdAt', 'DESC')
            .getMany();

        return reviews.map(review => ({
            ...review,
            createdAt: review.createdAt ? new Date(review.createdAt).toISOString() : new Date().toISOString(),
        }));
    }
}
