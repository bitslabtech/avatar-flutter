import { Module } from '@nestjs/common';
import { ConfigModule } from './config/config.module';
import { ThrottlerModule } from '@nestjs/throttler';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { OrdersModule } from './modules/orders/orders.module';
import { QuotationsModule } from './modules/quotations/quotations.module';
import { PricingModule } from './modules/pricing/pricing.module';
import { CourierModule } from './modules/courier/courier.module';
import { SettingsModule } from './modules/settings/settings.module';
import { WhatsAppModule } from './modules/whatsapp/whatsapp.module';
import { AdminModule } from './modules/admin/admin.module';
import { HealthModule } from './modules/health/health.module';
import { BrandsModule } from './modules/brands/brands.module';
import { ProductsModule } from './modules/products/products.module';
import { GstModule } from './modules/gst/gst.module';
import { UploadsModule } from './modules/uploads/uploads.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { AddressesModule } from './modules/addresses/addresses.module';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';
import { RolesGuard } from './common/guards/roles.guard';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { ThrottlerGuard } from '@nestjs/throttler';

import { ScheduleModule } from '@nestjs/schedule';
import { SchedulerModule } from './modules/scheduler/scheduler.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { WishlistModule } from './modules/wishlist/wishlist.module';
import { AuditLogsModule } from './modules/audit-logs/audit-logs.module';

import { ContentModule } from './modules/content/content.module';
import { ContactSettingsModule } from './modules/contact-settings/contact-settings.module';
import { ReportsModule } from './modules/reports/reports.module';

@Module({
  imports: [
    ConfigModule,
    ThrottlerModule.forRoot([
      {
        ttl: 60000, // 1 minute
        limit: 30000, // Increased to 30000 requests per minute
      },
    ]),
    ScheduleModule.forRoot(),
    DatabaseModule,
    AuthModule,
    UsersModule,
    CatalogModule,
    OrdersModule,
    QuotationsModule,
    PricingModule,
    CourierModule,
    SettingsModule,
    WhatsAppModule,
    AdminModule,
    HealthModule,
    BrandsModule,
    ProductsModule,
    GstModule,
    UploadsModule,
    ReviewsModule,
    AddressesModule,
    AddressesModule,
    SchedulerModule,
    NotificationsModule,
    WishlistModule,
    AuditLogsModule,
    ReportsModule,
    ContentModule,
    ContactSettingsModule,
  ],
  providers: [
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: TransformInterceptor,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: LoggingInterceptor,
    },
    // {
    //   provide: APP_GUARD,
    //   useClass: ThrottlerGuard,
    // },
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: RolesGuard,
    },
  ],
})
export class AppModule { }
// Trigger hot reload for WishlistModule

// Trigger hot reload for AuditLogsModule
