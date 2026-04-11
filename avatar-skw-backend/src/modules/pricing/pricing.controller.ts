import {
  Controller,
  Get,
  Post,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Query,
  Res,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { PricingService } from './pricing.service';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '../users/entities/user.entity';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('Pricing')
@ApiBearerAuth()
@Controller('prices')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN)
export class PricingController {
  constructor(private readonly pricingService: PricingService) { }

  @Get('export-xlsx')
  async exportExcel(@Res() res: Response) {
    const buffer = await this.pricingService.exportToExcel();
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="products-pricing.xlsx"',
    );
    res.send(buffer);
  }

  @Post('import-xlsx')
  @UseInterceptors(FileInterceptor('file'))
  async importExcel(
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() user: any,
  ) {
    if (!file) {
      throw new Error('File is required');
    }
    return this.pricingService.importFromExcel(file, user.id);
  }

  @Get('changes')
  async getPriceChanges(
    @Query('productId') productId?: string,
    @Query('sku') sku?: string,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
  ) {
    return this.pricingService.getPriceChanges({
      productId,
      sku,
      page: page ? parseInt(page.toString(), 10) : undefined,
      limit: limit ? parseInt(limit.toString(), 10) : undefined,
    });
  }
}


