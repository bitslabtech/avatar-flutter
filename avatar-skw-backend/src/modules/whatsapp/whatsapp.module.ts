import { Module } from '@nestjs/common';
import { WhatsAppService } from './whatsapp.service';
import { SettingsModule } from '../settings/settings.module';
import { WhatsAppController } from './whatsapp.controller';

@Module({
  imports: [SettingsModule],
  controllers: [WhatsAppController],
  providers: [WhatsAppService],
  exports: [WhatsAppService],
})
export class WhatsAppModule { }


