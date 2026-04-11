import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderNumberService } from './order-number.service';
import { Order } from './entities/order.entity';
import { OrderItem } from './entities/order-item.entity';
import { Product } from '../products/entities/product.entity';
import { User } from '../users/entities/user.entity';
import { Quotation } from '../quotations/entities/quotation.entity';
import { CourierModule } from '../courier/courier.module';
import { WhatsAppModule } from '../whatsapp/whatsapp.module';
import { CatalogModule } from '../catalog/catalog.module';
import { AddressesModule } from '../addresses/addresses.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuditLogsModule } from '../audit-logs/audit-logs.module';
import { SettingsModule } from '../settings/settings.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, OrderItem, Product, User, Quotation]),
    CourierModule,
    WhatsAppModule,
    CatalogModule,
    AddressesModule,
    NotificationsModule,
    AuditLogsModule,
    SettingsModule,
  ],
  controllers: [OrdersController],
  providers: [OrdersService, OrderNumberService],
  exports: [OrdersService, OrderNumberService],
})
export class OrdersModule { }

