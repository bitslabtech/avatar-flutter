import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { Order } from '../orders/entities/order.entity';
import { Quotation } from '../quotations/entities/quotation.entity';
import { User } from '../users/entities/user.entity';
import { OrdersModule } from '../orders/orders.module';
import { QuotationsModule } from '../quotations/quotations.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, Quotation, User]),
    OrdersModule,
    QuotationsModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule { }


