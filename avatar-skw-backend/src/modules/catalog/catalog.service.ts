import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../products/entities/product.entity';
import { Banner } from '../products/entities/banner.entity';
import { Category } from '../products/entities/category.entity';

@Injectable()
export class CatalogService {
  constructor(
    @InjectRepository(Product)
    private productRepository: Repository<Product>,
    @InjectRepository(Banner)
    private bannerRepository: Repository<Banner>,
    @InjectRepository(Category)
    private categoryRepository: Repository<Category>,
  ) { }

  async findAll(
    filters?: {
      brand?: string;
      category?: string;
      search?: string;
      page?: number;
      limit?: number;
      sortBy?: string;
      sortOrder?: 'ASC' | 'DESC';
    },
    showPrices: boolean = false, // Default to false (hide prices for guests)
  ) {
    // Build raw query for robust Distinct On logic
    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const skip = (page - 1) * limit;
    const sortBy = filters?.sortBy || 'createdAt';
    const sortOrder = filters?.sortOrder || 'DESC';

    let whereClause = 'p."isActive" = true';
    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.brand) {
      whereClause += ` AND b."name" = $${paramIndex++}`;
      params.push(filters.brand);
    }

    if (filters?.category) {
      whereClause += ` AND c."name" = $${paramIndex++}`;
      params.push(filters.category);
    }

    if (filters?.search) {
      const terms = filters.search.trim().split(/\s+/);

      terms.forEach(term => {
        // Name: Contains (%term%)
        // SKU: Starts With (term%) for stricter matching
        whereClause += ` AND (p."name" ILIKE $${paramIndex} OR p."sku" ILIKE $${paramIndex + 1})`;
        params.push(`%${term}%`);
        params.push(`${term}%`);
        paramIndex += 2;
      });
    }

    // Determine Order Clause
    let orderClause = '';
    // Always keep grouping verification
    const groupClause = `COALESCE(p."variation_group_id", p."id"::text)`;

    if (sortBy === 'price') {
      // For price sort, we want grouped items to resolve to the min/max price depending on sort
      // BUT Distinct ON picks the first row. 
      // To support correct price sorting with grouping:
      // 1. Sort inside the subquery by the target sort column to ensure DISTINCT ON picks the right variant
      // 2. Sort the final result by the target column

      if (sortOrder === 'ASC') {
        // Low to High: Inside, sort by price ASC so we get cheapest variant. Outside, sort by price ASC.
        orderClause = `ORDER BY grouped_products."price" ASC`;
      } else {
        // High to Low: Inside, sort by price DESC so we get most expensive variant. Outside, sort by price DESC.
        orderClause = `ORDER BY grouped_products."price" DESC`;
      }
    } else {
      // Default (Newest): Sort by createdAt
      orderClause = `ORDER BY grouped_products."createdAt" ${sortOrder}`;
    }

    // Inner sort must align with Distinct ON
    // Distinct ON requires the leading ORDER BY columns to match the DISTINCT ON expressions
    // So we must start with variation_group_id
    // Then we add our secondary sort to pick the right variant
    let innerOrder = '';
    if (sortBy === 'price') {
      innerOrder = `ORDER BY ${groupClause}, p."price" ${sortOrder}`;
    } else {
      innerOrder = `ORDER BY ${groupClause}, p."createdAt" DESC`; // Default newest variant
    }

    // Main Query
    const sql = `
      SELECT * FROM (
        SELECT DISTINCT ON (${groupClause}) 
          p.*, 
          b."name" as "brand_name", 
          c."name" as "category_name"
        FROM "products" p
        LEFT JOIN "brands" b ON p."brandId" = b."id"
        LEFT JOIN "categories" c ON p."categoryId" = c."id"
        WHERE ${whereClause}
        ${innerOrder}
      ) as grouped_products
      ${orderClause}
      LIMIT $${paramIndex++} OFFSET $${paramIndex}
    `;

    params.push(limit, skip);

    // Count Query (approximate, ignoring grouping for speed or use CTE for exact)
    // For now, simple count matching filters
    const countSql = `
      SELECT COUNT(*) as "total"
      FROM "products" p
      LEFT JOIN "brands" b ON p."brandId" = b."id"
      LEFT JOIN "categories" c ON p."categoryId" = c."id"
      WHERE ${whereClause}
    `;

    const [rows, countResult] = await Promise.all([
      this.productRepository.query(sql, params),
      this.productRepository.query(countSql, params.slice(0, params.length - 2)) // Exclude limit/offset
    ]);

    const total = parseInt(countResult[0].total, 10);

    // Map raw rows to Product entities manually
    // Map raw rows to Product entities manually
    const products = rows.map((row: any) => {
      const product = new Product();
      Object.assign(product, row);

      // Manually map snake_case back to camelCase properties for DTO
      if (row.variation_group_id) product.variationGroupId = row.variation_group_id;
      if (row.variation_type) product.variationType = row.variation_type;

      // Fix: TypeORM 'simple-array' returns a string in raw SQL, need to split it
      if (typeof row.images === 'string') {
        product.images = row.images.split(',');
      } else if (Array.isArray(row.images)) {
        product.images = row.images;
      } else {
        product.images = [];
      }

      product.brandRel = { name: row.brand_name } as any;
      product.category = { name: row.category_name } as any;
      return product;
    });

    return {
      products: products.map((p) => this.toProductDto(p, showPrices)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findOne(idOrSku: string, showPrices: boolean = false) {
    const product = await this.productRepository.findOne({
      where: [{ id: idOrSku }, { sku: idOrSku }],
      relations: ['category', 'brandRel'],
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    return this.toProductDto(product, showPrices);
  }

  async getBrands() {
    const result = await this.productRepository
      .createQueryBuilder('product')
      .leftJoin('product.brandRel', 'brandRel')
      .select('DISTINCT brandRel.name', 'brand')
      .where('brandRel.isActive = :isActive', { isActive: true })
      .orderBy('brandRel.name', 'ASC')
      .getRawMany();

    return result.map((r) => r.brand);
  }

  async getCategories() {
    return this.categoryRepository.find({
      where: { isActive: true },
      order: { order: 'ASC', name: 'ASC' },
      // Return full object including imageUrl, title, description
    });
  }

  /**
   * Get promotional banners for home screen slider
   * Returns array of banner objects with image URLs and optional links
   * In production, this could be stored in database or settings
   */
  async getBanners() {
    return this.bannerRepository.find({
      where: { isActive: true },
      order: { order: 'ASC', createdAt: 'DESC' },
    });
  }

  private toProductDto(product: Product, showPrices: boolean = true) {
    return {
      id: product.id,
      sku: product.sku,
      name: product.name,
      brand: product.brandRel?.name || 'Generic',
      category: product.category?.name || 'Uncategorized',
      price: product.price ? Number(product.price) : 0,
      mrp: product.mrp ? Number(product.mrp) : 0,
      taxPercent: product.gstPercent,
      specs: product.specifications || {},
      warrantyPeriod: null,
      energyRating: null,
      modelNumber: null,
      installationRequired: false,
      images: product.images || [],
      description: product.description,
      variationGroupId: product.variationGroupId,
      variationType: product.variationType,
      variant: product.variant,
      size: product.size,
    };
  }

  async findByGroup(groupId: string, showPrices: boolean = false) {
    const products = await this.productRepository.find({
      where: { variationGroupId: groupId, isActive: true },
      order: { variationType: 'ASC', variant: 'ASC', size: 'ASC' },
      relations: ['category', 'brandRel'],
    });

    return products.map(p => this.toProductDto(p, showPrices));
  }
}


