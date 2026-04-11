import {
    Controller,
    Get,
    Post,
    Body,
    Patch,
    Param,
    Delete,
    UseGuards,
    Request,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { AddressesService } from './addresses.service';
import { CreateAddressDto, UpdateAddressDto } from './dto/address.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@ApiTags('addresses')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('addresses')
export class AddressesController {
    constructor(private readonly addressesService: AddressesService) { }

    @Post()
    @ApiOperation({ summary: 'Create a new address' })
    create(@Request() req, @Body() createAddressDto: CreateAddressDto) {
        return this.addressesService.create(req.user.id, createAddressDto);
    }

    @Get()
    @ApiOperation({ summary: 'Get all addresses for current user' })
    findAll(@Request() req) {
        return this.addressesService.findAllByUser(req.user.id);
    }

    @Get('user/:userId')
    @ApiOperation({ summary: 'Get all addresses for a specific user (Admin only)' })
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    findByUserId(@Param('userId') userId: string) {
        return this.addressesService.findAllByUser(userId);
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get a single address by ID' })
    findOne(@Request() req, @Param('id') id: string) {
        return this.addressesService.findOne(id, req.user.id);
    }

    @Patch(':id')
    @ApiOperation({ summary: 'Update an address' })
    update(
        @Request() req,
        @Param('id') id: string,
        @Body() updateAddressDto: UpdateAddressDto,
    ) {
        return this.addressesService.update(id, req.user.id, updateAddressDto);
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete an address' })
    async remove(@Request() req, @Param('id') id: string) {
        await this.addressesService.delete(id, req.user.id);
        return { message: 'Address deleted successfully' };
    }

    @Post('user/:userId')
    @ApiOperation({ summary: 'Create address for a specific user (Admin only)' })
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    createForUser(
        @Param('userId') userId: string,
        @Body() createAddressDto: CreateAddressDto,
    ) {
        return this.addressesService.create(userId, createAddressDto);
    }
}
