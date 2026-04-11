import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { DealersAdminController } from './dealers-admin.controller';
import { DealersAdminService } from './dealers-admin.service';
import { User } from './entities/user.entity';
import { DealerTier } from './entities/dealer-tier.entity';
import { WhatsAppModule } from '../whatsapp/whatsapp.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [TypeOrmModule.forFeature([User, DealerTier]), WhatsAppModule, NotificationsModule],
  controllers: [UsersController, DealersAdminController],
  providers: [UsersService, DealersAdminService],
  exports: [UsersService],
})
export class UsersModule { }


