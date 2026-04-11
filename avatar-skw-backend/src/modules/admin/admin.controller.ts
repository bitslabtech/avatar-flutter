import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { CreateOrderDto } from '../orders/dto/orders.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { UserRole } from '../users/entities/user.entity';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('Admin')
@ApiBearerAuth()
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) { }

  @Get('orders/dashboard')
  async getDashboard() {
    return this.adminService.getDashboard();
  }

  @Post('orders')
  async createOrderOnBehalf(
    @Body('userId', ParseUUIDPipe) userId: string,
    @Body('order') createDto: CreateOrderDto,
  ) {
    return this.adminService.createOrderOnBehalf(userId, createDto);
  }

  @Post('quotes')
  async createQuotationOnBehalf(
    @Body('userId', ParseUUIDPipe) userId: string,
    @Body('quotation') createDto: CreateOrderDto,
  ) {
    return this.adminService.createQuotationOnBehalf(userId, createDto);
  }
}


