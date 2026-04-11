import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
  Res,
} from '@nestjs/common';
import { Response } from 'express';
import { QuotationsService } from './quotations.service';
import { CreateOrderDto } from '../orders/dto/orders.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ApiBearerAuth, ApiTags, ApiOperation, ApiBody } from '@nestjs/swagger';

@ApiTags('Quotations')
@ApiBearerAuth()
@Controller('quotes')
@UseGuards(JwtAuthGuard)
export class QuotationsController {
  constructor(private readonly quotationsService: QuotationsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a quotation (similar to order draft)' })
  @ApiBody({
    type: CreateOrderDto,
    examples: {
      default: {
        summary: 'Sample quotation',
        value: {
          items: [
            { productId: '8d9b0f4d-1234-4c2f-9b0b-123456789abc', qty: 1 },
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
  async create(
    @CurrentUser() user: any,
    @Body() createDto: CreateOrderDto,
  ) {
    return this.quotationsService.createQuotation(user.id, createDto);
  }

  @Get()
  async findAll(@CurrentUser() user: any) {
    return this.quotationsService.findAll(user.id, user.role);
  }

  @Get(':id')
  async findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: any,
  ) {
    return this.quotationsService.findOne(id, user.id, user.role);
  }

  @Get(':id/quotation.pdf')
  async getQuotationPdf(
    @Param('id', ParseUUIDPipe) id: string,
    @Res() res: Response,
    @CurrentUser() user: any,
  ) {
    const pdf = await this.quotationsService.generateQuotationPdf(id);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="quotation-${id}.pdf"`,
    );
    res.send(pdf);
  }
}


