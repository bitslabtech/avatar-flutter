import { Controller, Get, Put, Body, UseGuards } from '@nestjs/common';
import { ContactSettingsService } from './contact-settings.service';
import { UpdateContactSettingsDto } from './dto/update-contact-settings.dto';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('contact-settings')
export class ContactSettingsController {
    constructor(private readonly contactSettingsService: ContactSettingsService) { }

    @Public()
    @Get()
    async getSettings() {
        return this.contactSettingsService.getSettings();
    }

    @Roles(UserRole.SUPER_ADMIN)
    @Put()
    async updateSettings(@Body() updateDto: UpdateContactSettingsDto) {
        return this.contactSettingsService.updateSettings(updateDto);
    }
}
