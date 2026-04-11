import { Controller, Get, Param, Query } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import {
  ApiTags,
  ApiOperation,
  ApiQuery,
} from '@nestjs/swagger';

@ApiTags('Catalog')
@Controller('products')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) { }

  @Public()
  @Get()
  @ApiOperation({ summary: 'List active products (public)' })
  @ApiQuery({ name: 'brand', required: false })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'page', required: false })
  @ApiQuery({ name: 'limit', required: false })
  @ApiQuery({ name: 'sortBy', required: false, enum: ['price', 'createdAt'] })
  @ApiQuery({ name: 'sortOrder', required: false, enum: ['ASC', 'DESC'] })
  async findAll(
    @Query('brand') brand?: string,
    @Query('category') category?: string,
    @Query('search') search?: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('sortBy') sortBy?: string,
    @Query('sortOrder') sortOrder?: 'ASC' | 'DESC',
    @CurrentUser() user?: any,
  ) {
    return this.catalogService.findAll({
      brand,
      category,
      search,
      page: page ? parseInt(page.toString(), 10) : undefined,
      limit: limit ? parseInt(limit.toString(), 10) : undefined,
      sortBy,
      sortOrder,
    }, !!user); // Pass true if user is authenticated
  }



  @Public()
  @Get('meta/brands')
  @ApiOperation({ summary: 'List all brands (public)' })
  async getBrands() {
    return this.catalogService.getBrands();
  }

  @Public()
  @Get('meta/categories')
  @ApiOperation({ summary: 'List all categories (public)' })
  async getCategories() {
    return this.catalogService.getCategories();
  }


  @Public()
  @Get('banners')
  @ApiOperation({ summary: 'Get promotional banners for home screen (public)' })
  async getBanners() {
    return this.catalogService.getBanners();
  }



  @Public()
  @Get(':idOrSku')
  @ApiOperation({ summary: 'Get product by id or SKU (public)' })
  async findOne(
    @Param('idOrSku') idOrSku: string,
    @CurrentUser() user?: any,
  ) {
    return this.catalogService.findOne(idOrSku, !!user); // Pass true if user is authenticated
  }

  @Public()
  @Get('group/:groupId')
  @ApiOperation({ summary: 'Get products by variation group (public)' })
  async findByGroup(
    @Param('groupId') groupId: string,
    @CurrentUser() user?: any,
  ) {
    return this.catalogService.findByGroup(groupId, !!user);
  }
}


