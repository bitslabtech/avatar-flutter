import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards } from '@nestjs/common';
import { BannersService } from './banners.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Banners')
@Controller('admin/banners')
@UseGuards(JwtAuthGuard, RolesGuard)
export class BannersController {
    constructor(private readonly bannersService: BannersService) { }

    @Get()
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @ApiOperation({ summary: 'List all banners (Admin)' })
    findAll() {
        return this.bannersService.findAll();
    }

    @Post()
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @ApiOperation({ summary: 'Create a new banner (Admin)' })
    create(@Body() createBannerDto: any) {
        return this.bannersService.create(createBannerDto);
    }

    @Patch(':id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @ApiOperation({ summary: 'Update a banner (Admin)' })
    update(@Param('id') id: string, @Body() updateBannerDto: any) {
        return this.bannersService.update(id, updateBannerDto);
    }

    @Delete(':id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @ApiOperation({ summary: 'Delete a banner (Admin)' })
    remove(@Param('id') id: string) {
        return this.bannersService.remove(id);
    }
    @Patch('reorder')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @ApiOperation({ summary: 'Reorder banners (Admin)' })
    reorder(@Body() body: { ids: string[] }) {
        return this.bannersService.reorder(body.ids);
    }
}
