import { Module } from '@nestjs/common';
import { SchedulerService } from './scheduler.service';
import { OrdersModule } from '../orders/orders.module';
import { WhatsAppModule } from '../whatsapp/whatsapp.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
    imports: [
        OrdersModule,
        WhatsAppModule,
        NotificationsModule,
    ],
    providers: [SchedulerService],
})
export class SchedulerModule { }
