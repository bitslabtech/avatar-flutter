import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards } from '@nestjs/common';
import { GstService } from './gst.service';
import { CreateGstDto, UpdateGstDto } from './dto/gst.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('gst')
@UseGuards(JwtAuthGuard, RolesGuard)
export class GstController {
    constructor(private readonly gstService: GstService) { }

    @Get()
    findAll() {
        return this.gstService.findAll();
    }

    @Get(':id')
    findOne(@Param('id') id: string) {
        return this.gstService.findOne(id);
    }

    @Post()
    @Roles(UserRole.SUPER_ADMIN)
    create(@Body() createGstDto: CreateGstDto) {
        return this.gstService.create(createGstDto);
    }

    @Patch(':id')
    @Roles(UserRole.SUPER_ADMIN)
    update(@Param('id') id: string, @Body() updateGstDto: UpdateGstDto) {
        return this.gstService.update(id, updateGstDto);
    }

    @Delete(':id')
    @Roles(UserRole.SUPER_ADMIN)
    remove(@Param('id') id: string) {
        return this.gstService.remove(id);
    }
}
