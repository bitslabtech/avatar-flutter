import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Category } from './entities/category.entity';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';

@Injectable()
export class CategoriesService {
    constructor(
        @InjectRepository(Category)
        private categoryRepository: Repository<Category>,
    ) { }

    async findAll() {
        // Return categories with product count for the dashboard
        return this.categoryRepository
            .createQueryBuilder('category')
            .loadRelationCountAndMap('category.productCount', 'category.products')
            .orderBy('category.order', 'ASC')
            .addOrderBy('category.name', 'ASC')
            .getMany();
    }

    async findOne(id: string) {
        const category = await this.categoryRepository.findOne({
            where: { id },
            relations: ['products']
        });

        if (!category) {
            throw new NotFoundException(`Category with ID ${id} not found`);
        }

        return category;
    }

    async create(createCategoryDto: CreateCategoryDto) {
        const category = this.categoryRepository.create(createCategoryDto);
        return this.categoryRepository.save(category);
    }

    async update(id: string, updateCategoryDto: UpdateCategoryDto) {
        const category = await this.findOne(id);
        Object.assign(category, updateCategoryDto);
        return this.categoryRepository.save(category);
    }

    async updateOrders(orders: { id: string; order: number }[]) {
        const updates = orders.map(item =>
            this.categoryRepository.update(item.id, { order: item.order })
        );
        await Promise.all(updates);
        return { success: true };
    }

    async remove(id: string) {
        const category = await this.findOne(id);
        // With onDelete: 'SET NULL' in Product entity, this will automatically unassign products
        return this.categoryRepository.remove(category);
    }
}
