import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Address } from './entities/address.entity';
import { CreateAddressDto, UpdateAddressDto } from './dto/address.dto';

@Injectable()
export class AddressesService {
    constructor(
        @InjectRepository(Address)
        private addressRepository: Repository<Address>,
    ) { }

    async create(userId: string, createAddressDto: CreateAddressDto): Promise<Address> {
        console.log('Creating address for userId:', userId);

        // If this is being set as default, unset other defaults
        if (createAddressDto.isDefault) {
            await this.addressRepository.update(
                { userId, isDefault: true },
                { isDefault: false },
            );
        }

        const address = this.addressRepository.create({
            ...createAddressDto,
            userId,
        });

        console.log('Address entity to save:', JSON.stringify(address, null, 2));

        return this.addressRepository.save(address);
    }

    async findAllByUser(userId: string): Promise<Address[]> {
        return this.addressRepository.find({
            where: { userId },
            order: { isDefault: 'DESC', createdAt: 'DESC' },
        });
    }

    async findOne(id: string, userId: string): Promise<Address> {
        const address = await this.addressRepository.findOne({
            where: { id, userId },
        });

        if (!address) {
            throw new NotFoundException('Address not found');
        }

        return address;
    }

    async update(id: string, userId: string, updateAddressDto: UpdateAddressDto): Promise<Address> {
        const address = await this.findOne(id, userId);

        // If setting as default, unset other defaults
        if (updateAddressDto.isDefault) {
            await this.addressRepository.update(
                { userId, isDefault: true, id: address.id },
                { isDefault: false },
            );
        }

        Object.assign(address, updateAddressDto);
        return this.addressRepository.save(address);
    }

    async delete(id: string, userId: string): Promise<void> {
        const address = await this.findOne(id, userId);
        await this.addressRepository.remove(address);
    }
}
