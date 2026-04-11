import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Banner } from './entities/banner.entity';

@Injectable()
export class BannersService {
    constructor(
        @InjectRepository(Banner)
        private bannersRepository: Repository<Banner>,
    ) { }

    async findAll() {
        return this.bannersRepository.find({
            order: { order: 'ASC', createdAt: 'DESC' },
        });
    }

    async findActive() {
        return this.bannersRepository.find({
            where: { isActive: true },
            order: { order: 'ASC', createdAt: 'DESC' },
        });
    }

    async create(createBannerDto: any) {
        const banner = this.bannersRepository.create(createBannerDto);
        return this.bannersRepository.save(banner);
    }

    async update(id: string, updateBannerDto: any) {
        const banner = await this.bannersRepository.findOne({ where: { id } });
        if (!banner) {
            throw new NotFoundException('Banner not found');
        }
        Object.assign(banner, updateBannerDto);
        return this.bannersRepository.save(banner);
    }

    async remove(id: string) {
        const result = await this.bannersRepository.delete(id);
        if (result.affected === 0) {
            throw new NotFoundException('Banner not found');
        }
        return { message: 'Banner deleted successfully' };
    }
    async reorder(ids: string[]) {
        // optimize: change to use a transaction or single query if possible, 
        // but for small lists, a loop is fine.
        for (let i = 0; i < ids.length; i++) {
            await this.bannersRepository.update(ids[i], { order: i });
        }
        return { message: 'Banners reordered successfully' };
    }
}
