import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Brand } from './entities/brand.entity';
import { CreateBrandDto, UpdateBrandDto } from './dto/brand.dto';

@Injectable()
export class BrandsService {
    constructor(
        @InjectRepository(Brand)
        private brandsRepository: Repository<Brand>,
    ) { }

    findAll() {
        return this.brandsRepository.createQueryBuilder('brand')
            .loadRelationCountAndMap('brand.productCount', 'brand.products')
            .orderBy('brand.name', 'ASC')
            .getMany();
    }

    async findOne(id: string) {
        const brand = await this.brandsRepository.findOne({ where: { id } });
        if (!brand) throw new NotFoundException(`Brand with ID ${id} not found`);
        return brand;
    }

    create(createBrandDto: CreateBrandDto) {
        const brand = this.brandsRepository.create(createBrandDto);
        return this.brandsRepository.save(brand);
    }

    async update(id: string, updateBrandDto: UpdateBrandDto) {
        const brand = await this.findOne(id);
        Object.assign(brand, updateBrandDto);
        return this.brandsRepository.save(brand);
    }

    async remove(id: string) {
        const brand = await this.findOne(id);
        return this.brandsRepository.remove(brand);
    }
}
