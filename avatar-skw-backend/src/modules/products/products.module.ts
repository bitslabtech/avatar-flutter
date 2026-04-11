import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CategoriesController } from './categories.controller';
import { CategoriesService } from './categories.service';
import { ProductsService } from './products.service';
import { ProductsController } from './products.controller';
import { BannersController } from './banners.controller'; // Ensure this matches filename
import { BannersService } from './banners.service'; // Ensure this matches filename
import { Product } from './entities/product.entity';
import { Category } from './entities/category.entity';
import { Banner } from './entities/banner.entity';

import { ProductsExcelService } from './products.excel.service';
import { Brand } from '../brands/entities/brand.entity';
import { AuditLogsModule } from '../audit-logs/audit-logs.module';

@Module({
    imports: [TypeOrmModule.forFeature([Product, Category, Banner, Brand]), AuditLogsModule],
    controllers: [ProductsController, CategoriesController, BannersController],
    providers: [ProductsService, CategoriesService, BannersService, ProductsExcelService],
    exports: [ProductsService, CategoriesService, BannersService, ProductsExcelService, TypeOrmModule],
})
export class ProductsModule { }
