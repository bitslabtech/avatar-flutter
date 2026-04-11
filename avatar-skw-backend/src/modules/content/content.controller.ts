import { Controller, Get, Post, Body, Put, Param, UseGuards, NotFoundException } from '@nestjs/common';
import { ContentService } from './content.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { Public } from '../../common/decorators/public.decorator';

@Controller('content')
export class ContentController {
    constructor(private readonly contentService: ContentService) { }

    @Public()
    @Get()
    findAll() {
        return this.contentService.findAll();
    }

    @Public()
    @Get(':key')
    async findOne(@Param('key') key: string) {
        const content = await this.contentService.findByKey(key);
        if (!content) {
            throw new NotFoundException(`Content with key ${key} not found`);
        }
        return content;
    }

    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
    @Put(':key')
    update(@Param('key') key: string, @Body() updateContentDto: { title: string; body: string; isActive: boolean }) {
        return this.contentService.update(key, updateContentDto);
    }
}
