import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ContactSettings } from './entities/contact-settings.entity';
import { UpdateContactSettingsDto } from './dto/update-contact-settings.dto';

@Injectable()
export class ContactSettingsService {
    constructor(
        @InjectRepository(ContactSettings)
        private readonly contactSettingsRepository: Repository<ContactSettings>,
    ) { }

    async getSettings(): Promise<ContactSettings> {
        // Get the active settings (there should only be one record)
        let settings = await this.contactSettingsRepository.findOne({
            where: { isActive: true },
        });

        // If no settings exist, create default one
        if (!settings) {
            settings = this.contactSettingsRepository.create({
                supportEmail: null,
                whatsappNumber: null,
                callNumber: null,
                isActive: true,
            });
            await this.contactSettingsRepository.save(settings);
        }

        return settings;
    }

    async updateSettings(updateDto: UpdateContactSettingsDto): Promise<ContactSettings> {
        const settings = await this.getSettings();

        Object.assign(settings, updateDto);

        return await this.contactSettingsRepository.save(settings);
    }
}
