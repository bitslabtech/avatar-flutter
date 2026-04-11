import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { SettingsService } from './settings.service';
import { CreateSettingDto, UpdateSettingDto } from './dto/settings.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { Public } from '../../common/decorators/public.decorator';
import { UserRole } from '../users/entities/user.entity';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('Settings')
@ApiBearerAuth()
@Controller('settings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) { }

  @Public()
  @Get('public-config')
  async getPublicConfig() {
    const maintenance = await this.settingsService.getSettingByKey('system.maintenance_mode');
    return {
      maintenance_mode: maintenance?.value === 'true',
    };
  }

  @Get()
  async getAll() {
    return this.settingsService.getPublicSettings();
  }

  @Get(':key')
  async getByKey(@Param('key') key: string) {
    return this.settingsService.getSettingByKey(key);
  }

  @Post()
  async create(@Body() createDto: CreateSettingDto) {
    return this.settingsService.createOrUpdate(createDto);
  }

  @Patch(':key')
  async update(@Param('key') key: string, @Body() updateDto: UpdateSettingDto) {
    return this.settingsService.update(key, updateDto);
  }
}


