import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CatalogController } from './catalog.controller';
import { CatalogService } from './catalog.service';
import { Product } from '../products/entities/product.entity';
import { Banner } from '../products/entities/banner.entity';
import { Category } from '../products/entities/category.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Product, Banner, Category])],
  controllers: [CatalogController],
  providers: [CatalogService],
  exports: [CatalogService],
})
export class CatalogModule { }


