import { Controller, Get, Post, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Reviews')
@Controller('reviews')
export class ReviewsController {
    constructor(private readonly reviewsService: ReviewsService) { }

    @Post()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(UserRole.CONSUMER, UserRole.DEALER)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Create a product review (Consumer/Dealer only)' })
    create(@Body() createReviewDto: CreateReviewDto, @Request() req) {
        return this.reviewsService.create(createReviewDto, req.user);
    }

    @Public() // Reviews are public
    @Get('product/:productId')
    @ApiOperation({ summary: 'Get reviews for a product' })
    findByProduct(@Param('productId') productId: string) {
        return this.reviewsService.findByProduct(productId);
    }
}
