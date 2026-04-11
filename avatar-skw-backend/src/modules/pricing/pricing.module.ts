import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PricingController } from './pricing.controller';
import { PricingService } from './pricing.service';
import { Product } from '../products/entities/product.entity';
import { PriceChangeLog } from './entities/price-change-log.entity';
import { User } from '../users/entities/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Product, PriceChangeLog, User])],
  controllers: [PricingController],
  providers: [PricingService],
})
export class PricingModule { }


