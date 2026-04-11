import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Res, UseInterceptors, UploadedFile, BadRequestException, Request, Ip, Query, DefaultValuePipe, ParseIntPipe } from '@nestjs/common';
import { ProductsService } from './products.service';
import { ProductsExcelService } from './products.excel.service';
import { CreateProductDto, UpdateProductDto } from './dto/product.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { Express } from 'express';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermission } from '../../common/decorators/permissions.decorator';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { AuditLogActionType, AuditLogStatus } from '../audit-logs/entities/audit-log.entity';

@Controller('admin/products')
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
export class ProductsController {
    constructor(
        private readonly productsService: ProductsService,
        private readonly excelService: ProductsExcelService,
        private readonly auditLogsService: AuditLogsService,
    ) { }

    @Get('export')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @RequirePermission('products', 'read')
    async exportProducts(@Res() res: Response) {
        const buffer = await this.excelService.exportProducts();

        res.set({
            'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition': 'attachment; filename=products_export.xlsx',
            'Content-Length': buffer.length,
        });

        res.end(buffer);
    }

    @Post('import')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @RequirePermission('products', 'create')
    @UseInterceptors(FileInterceptor('file'))
    async importProducts(@UploadedFile() file: Express.Multer.File) {
        if (!file) throw new BadRequestException('No file uploaded');
        return this.excelService.importProducts(file.buffer);
    }

    @Get()
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @RequirePermission('products', 'read')
    findAll(
        @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
        @Query('limit', new DefaultValuePipe(30), ParseIntPipe) limit: number,
        @Query('search') search?: string,
        @Query('category') category?: string,
        @Query('isActive') isActive?: string,
    ) {
        return this.productsService.findAll({ page, limit, search, category, isActive });
    }

    @Get(':id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @RequirePermission('products', 'read')
    findOne(@Param('id') id: string, @Request() req, @Ip() ip: string) {
        // Audit Log for Admin Viewing Product
        const user = req.user;
        if (user && (user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN)) {
            this.auditLogsService.logAction(
                user.id,
                AuditLogActionType.VIEW,
                `Viewed Product`,
                `Viewed details of product`,
                ip,
                AuditLogStatus.SUCCESS,
                id,
                'Product'
            ).catch(err => console.error('Failed to log admin view action', err));
        }
        return this.productsService.findOne(id);
    }

    @Get('group/:groupId')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @RequirePermission('products', 'read')
    findByGroup(@Param('groupId') groupId: string) {
        return this.productsService.findByVariationGroup(groupId);
    }

    @Post()
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @RequirePermission('products', 'create')
    create(@Body() createProductDto: CreateProductDto, @Request() req, @Ip() ip: string) {
        return this.productsService.create(createProductDto, req.user, ip);
    }

    @Patch(':id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @RequirePermission('products', 'update')
    update(@Param('id') id: string, @Body() updateProductDto: UpdateProductDto, @Request() req, @Ip() ip: string) {
        return this.productsService.update(id, updateProductDto, req.user, ip);
    }

    @Delete(':id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    @RequirePermission('products', 'delete')
    remove(@Param('id') id: string, @Request() req, @Ip() ip: string) {
        return this.productsService.remove(id, req.user, ip);
    }
}
