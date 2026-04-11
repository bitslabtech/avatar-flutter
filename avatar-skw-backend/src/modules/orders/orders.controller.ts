import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
  Res,
  Delete,
  Ip,
  Request,
  Query,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import { Response } from 'express';
import { OrdersService } from './orders.service';
import { CreateOrderDto, UpdateOrderStatusDto, CreateOrderOnBehalfDto, CreateOrderItemDto, ConfirmOrderDto } from './dto/orders.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermission } from '../../common/decorators/permissions.decorator';
import { UserRole } from '../users/entities/user.entity';
import {
  ApiBearerAuth,
  ApiTags,
  ApiOperation,
  ApiBody,
} from '@nestjs/swagger';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { AuditLogActionType, AuditLogStatus } from '../audit-logs/entities/audit-log.entity';

@ApiTags('Orders')
@ApiBearerAuth()
@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly auditLogsService: AuditLogsService,
  ) { }

  @Post('draft')
  @ApiOperation({
    summary: 'Create order draft (calculates totals, returns WhatsApp link)',
  })
  @ApiBody({
    type: CreateOrderDto,
    examples: {
      default: {
        summary: 'Sample order draft',
        value: {
          items: [
            { productId: '8d9b0f4d-1234-4c2f-9b0b-123456789abc', qty: 2 },
          ],
          address: {
            street: '123 MG Road',
            city: 'Bangalore',
            state: 'KA',
            zipCode: '560001',
            country: 'India',
            name: 'John Doe',
            phone: '9999000004',
          },
          courierPreference: 'blue-dart',
        },
      },
    },
  })
  async createDraft(
    @CurrentUser() user: any,
    @Body() createOrderDto: CreateOrderDto,
  ) {
    return this.ordersService.createOrderDraft(user.id, createOrderDto);
  }

  @Post('confirm')
  @ApiOperation({ summary: 'Confirm order (Draft -> Pending)' })
  async confirmOrder(
    @CurrentUser() user: any,
    @Body() confirmDto: ConfirmOrderDto,
  ) {
    console.log('🎯 CONTROLLER: POST /orders/confirm called by user:', user.id, 'body:', JSON.stringify(confirmDto).substring(0, 100));
    return this.ordersService.confirmOrder(user.id, confirmDto);
  }

  @Post('cart/items')
  @ApiOperation({ summary: 'Add item to cart (server-side management)' })
  async addToCart(
    @CurrentUser() user: any,
    @Body() itemDto: CreateOrderItemDto, // Reusing DTO for single item
  ) {
    console.log('DEBUG: addToCart called for user', user.id, 'with item:', JSON.stringify(itemDto));
    return this.ordersService.addItemToCart(user.id, itemDto);
  }

  @Delete('cart/items/:productId')
  @ApiOperation({ summary: 'Remove item from cart' })
  async removeFromCart(
    @Param('productId') productId: string,
    @CurrentUser() user: any,
  ) {
    return this.ordersService.removeItemFromCart(user.id, productId);
  }

  @Patch('cart/items/:productId')
  @ApiOperation({ summary: 'Update item quantity in cart' })
  async updateCartItem(
    @Param('productId') productId: string,
    @Body('qty') qty: number,
    @CurrentUser() user: any,
  ) {
    return this.ordersService.updateCartItem(user.id, productId, qty);
  }

  // DELETE method for removal
  @Get('cart/remove/:productId') // GET variant for easy testing/links? No, standard API.
  async removeFromCartGet(@CurrentUser() user: any, @Param('productId') productId: string) {
    return this.ordersService.removeItemFromCart(user.id, productId);
  }

  // Real DELETE endpoint
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Remove item from cart' })
  @Post('cart/remove-item') // Using POST to avoid any body issues, passing productId in body or query? Param is better.
  async removeItem(@CurrentUser() user: any, @Body('productId') productId: string) {
    return this.ordersService.removeItemFromCart(user.id, productId);
  }

  @Post('create-on-behalf')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @RequirePermission('orders', 'create')
  @ApiOperation({ summary: 'Create order on behalf of user (Admin)' })
  async createOnBehalf(
    @Body() dto: CreateOrderOnBehalfDto,
    @CurrentUser() admin: any,
    @Ip() ip: string,
  ) {
    return this.ordersService.createOrderOnBehalf(dto, admin.id, ip);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get order statistics' })
  async getStats(@CurrentUser() user: any) {
    return this.ordersService.getStats(user.id, user.role);
  }

  @Get()
  async findAll(
    @CurrentUser() user: any,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: string,
    @Query('search') search?: string,
  ) {
    return this.ordersService.findAll(user.id, user.role, { page, limit, status, search });
  }

  @Get('draft')
  @ApiOperation({ summary: 'Get current cart/draft order without creating one' })
  async getCurrentDraft(@CurrentUser() user: any) {
    return this.ordersService.getCurrentDraft(user.id);
  }

  @Get(':id')
  async findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: any,
    @Ip() ip: string,
  ) {
    // Audit Log for Admin Viewing Order
    if (user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN) {
      this.auditLogsService.logAction(
        user.id,
        AuditLogActionType.VIEW,
        `Viewed Order`,
        `Viewed details of order`,
        ip,
        AuditLogStatus.SUCCESS,
        id,
        'Order'
      ).catch(err => console.error('Failed to log admin view action', err));
    }
    return this.ordersService.findOne(id, user.id, user.role);
  }

  @Patch(':id/status')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @RequirePermission('orders', 'update')
  async updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateDto: UpdateOrderStatusDto,
    @CurrentUser() user: any,
    @Ip() ip: string,
  ) {
    console.log('🎯 CONTROLLER - Received updateStatus request:', { id, updateDto, rawBody: JSON.stringify(updateDto) });
    const result = await this.ordersService.updateStatus(id, updateDto, user.id, user.role, ip);
    console.log('🎯 CONTROLLER - Returning result:', { estimatedDeliveryDate: result.estimatedDeliveryDate });
    return result;
  }

  @Patch(':id/items')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @RequirePermission('orders', 'update')
  @ApiOperation({ summary: 'Update order items (Admin)' })
  async updateOrderItems(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { items: { productId: string; qty: number }[] },
    @CurrentUser() user: any,
    @Ip() ip: string,
  ) {
    return this.ordersService.updateOrderItems(id, body.items, user.id, ip);
  }

  @Get(':id/proforma.pdf')
  async getProformaInvoice(
    @Param('id', ParseUUIDPipe) id: string,
    @Res() res: Response,
    @CurrentUser() user: any,
  ) {
    const pdf = await this.ordersService.generateProformaInvoice(id);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename = "proforma-${id}.pdf"`,
    );
    res.send(pdf);
  }

  @Delete(':id')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  @RequirePermission('orders', 'delete')
  @ApiOperation({ summary: 'Delete order (Superadmin/Admin only)' })
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.remove(id);
  }
}


