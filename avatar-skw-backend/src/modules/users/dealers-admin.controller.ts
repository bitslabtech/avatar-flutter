import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  UseGuards,
  ParseUUIDPipe,
  Patch,
  Query,
} from '@nestjs/common';
import { DealersAdminService } from './dealers-admin.service';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ApproveDealerDto, RejectDealerDto } from './dto/dealers-admin.dto';
import { UpdateDealerProfileDto } from './dto/update-dealer-profile.dto';
import { UserRole } from './entities/user.entity';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('Dealer Admin')
@ApiBearerAuth()
@Controller('users/dealers')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
export class DealersAdminController {
  constructor(private readonly dealersAdminService: DealersAdminService) { }

  @Get('applications')
  async getApplications() {
    return this.dealersAdminService.getPendingApplications();
  }

  @Get(':id')
  async getDealer(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('includeDeleted') includeDeleted?: string,
  ) {
    return this.dealersAdminService.getDealer(id, includeDeleted === 'true');
  }

  @Post(':id/approve')
  async approveDealer(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() approveDto: ApproveDealerDto,
  ) {
    return this.dealersAdminService.approveDealer(id, approveDto);
  }

  @Post(':id/reject')
  async rejectDealer(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() rejectDto: RejectDealerDto,
  ) {
    return this.dealersAdminService.rejectDealer(id, rejectDto);
  }

  @Patch(':id')
  async updateDealerProfile(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateDealerProfileDto,
  ) {
    return this.dealersAdminService.updateDealerProfile(id, dto);
  }
}


