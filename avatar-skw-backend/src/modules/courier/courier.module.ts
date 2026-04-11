import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CourierService } from './courier.service';
import { CourierRule } from './entities/courier-rule.entity';
import { SettingsModule } from '../settings/settings.module';

@Module({
  imports: [TypeOrmModule.forFeature([CourierRule]), SettingsModule],
  providers: [CourierService],
  exports: [CourierService],
})
export class CourierModule {}


