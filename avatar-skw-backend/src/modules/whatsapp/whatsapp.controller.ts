import { Controller, Post, UseGuards, Body } from '@nestjs/common';
import { WhatsAppService } from './whatsapp.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('WhatsApp')
@ApiBearerAuth()
@Controller('whatsapp')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
export class WhatsAppController {
    constructor(private readonly whatsappService: WhatsAppService) { }

    @Post('test')
    async testConnection() {
        return this.whatsappService.testConnection();
    }

    @Post('test-template')
    async testTemplate(@Body() body: { phone: string; templateName: string; languageCode?: string; type?: string }) {
        return this.whatsappService.testTemplate(body.phone, body.templateName, body.languageCode, body.type);
    }
}
