import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ContactSettingsController } from './contact-settings.controller';
import { ContactSettingsService } from './contact-settings.service';
import { ContactSettings } from './entities/contact-settings.entity';

@Module({
    imports: [TypeOrmModule.forFeature([ContactSettings])],
    controllers: [ContactSettingsController],
    providers: [ContactSettingsService],
    exports: [ContactSettingsService],
})
export class ContactSettingsModule { }
