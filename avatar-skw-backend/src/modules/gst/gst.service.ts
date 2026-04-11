import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GstRate } from './entities/gst.entity';
import { CreateGstDto, UpdateGstDto } from './dto/gst.dto';

@Injectable()
export class GstService {
    constructor(
        @InjectRepository(GstRate)
        private gstRepository: Repository<GstRate>,
    ) { }

    findAll() {
        return this.gstRepository.find({ order: { percentage: 'ASC' } });
    }

    async findOne(id: string) {
        const gst = await this.gstRepository.findOne({ where: { id } });
        if (!gst) throw new NotFoundException(`GST Rate with ID ${id} not found`);
        return gst;
    }

    async create(createGstDto: CreateGstDto) {
        // Check for duplicate percentage
        const existing = await this.gstRepository.findOne({ where: { percentage: createGstDto.percentage } });
        if (existing) {
            throw new ConflictException(`GST Rate ${createGstDto.percentage}% already exists`);
        }

        const gst = this.gstRepository.create(createGstDto);
        return this.gstRepository.save(gst);
    }

    async update(id: string, updateGstDto: UpdateGstDto) {
        const gst = await this.findOne(id);

        if (updateGstDto.percentage !== undefined && updateGstDto.percentage !== gst.percentage) {
            const existing = await this.gstRepository.findOne({ where: { percentage: updateGstDto.percentage } });
            if (existing) throw new ConflictException(`GST Rate ${updateGstDto.percentage}% already exists`);
        }

        Object.assign(gst, updateGstDto);
        return this.gstRepository.save(gst);
    }

    async remove(id: string) {
        const gst = await this.findOne(id);
        return this.gstRepository.remove(gst);
    }
}
