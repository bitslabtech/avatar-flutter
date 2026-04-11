import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Content } from './entities/content.entity';

@Injectable()
export class ContentService {
    constructor(
        @InjectRepository(Content)
        private contentRepository: Repository<Content>,
    ) { }

    findAll() {
        return this.contentRepository.find({
            select: ['id', 'key', 'title', 'isActive', 'updatedAt'],
            order: { title: 'ASC' }
        });
    }

    findByKey(key: string) {
        return this.contentRepository.findOne({ where: { key } });
    }

    async update(key: string, updateContentDto: { title: string; body: string; isActive: boolean }) {
        const content = await this.findByKey(key);
        if (!content) {
            throw new NotFoundException(`Content with key ${key} not found`);
        }

        // Update fields
        if (updateContentDto.title !== undefined) content.title = updateContentDto.title;
        if (updateContentDto.body !== undefined) content.body = updateContentDto.body;
        if (updateContentDto.isActive !== undefined) content.isActive = updateContentDto.isActive;

        return this.contentRepository.save(content);
    }
}
