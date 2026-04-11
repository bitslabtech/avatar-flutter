
import { Controller, Get, Post, Param, UseGuards, Req } from '@nestjs/common';
import { WishlistService } from './wishlist.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Wishlist')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('wishlist')
export class WishlistController {
    constructor(private readonly wishlistService: WishlistService) { }

    @Post('toggle/:productId')
    @ApiOperation({ summary: 'Toggle product in wishlist' })
    toggle(@Req() req, @Param('productId') productId: string) {
        return this.wishlistService.toggle(req.user, productId);
    }

    @Get()
    @ApiOperation({ summary: 'Get user wishlist' })
    findAll(@Req() req) {
        return this.wishlistService.findAll(req.user);
    }

    @Get('check/:productId')
    @ApiOperation({ summary: 'Check if product is in wishlist' })
    checkStatus(@Req() req, @Param('productId') productId: string) {
        return this.wishlistService.checkStatus(req.user, productId);
    }
}
