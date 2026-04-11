import { Controller, Get, Post, Patch, Delete, Body, UseGuards, Query, Param, UseInterceptors, UploadedFile, Ip, HttpCode, HttpStatus } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { UsersService } from './users.service';
import { UpdateProfileDto, CreateAdminDto, UpdateAdminPermissionsDto, ChangePasswordDto } from './dto/users.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from './entities/user.entity';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Users')
@ApiBearerAuth()
@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) { }

  @Get('me')
  async getMe(@CurrentUser() user: any) {
    return this.usersService.getProfile(user.id);
  }

  @Patch('me')
  async updateProfile(
    @CurrentUser() user: any,
    @Body() updateDto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(user.id, updateDto);
  }

  @Patch('me/change-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Change own password (requires current password)' })
  async changePassword(
    @CurrentUser() user: any,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.usersService.changePassword(user.id, dto.currentPassword, dto.newPassword);
  }

  /* ======================================================
     ADMIN MANAGEMENT (SUPER ADMIN ONLY)
     ====================================================== */

  @Post('admins')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  async createAdmin(@Body() createDto: CreateAdminDto, @CurrentUser() user: any, @Ip() ip: string) {
    return this.usersService.createAdmin(createDto, user.id, ip);
  }

  @Get('admins')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  async getAdmins() {
    return this.usersService.getAdmins();
  }

  @Patch('admins/:id/permissions')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  async updateAdminPermissions(
    @Param('id') id: string,
    @Body() dto: UpdateAdminPermissionsDto,
    @CurrentUser() user: any,
    @Ip() ip: string,
  ) {
    return this.usersService.updatePermissions(id, dto.permissions, user.id, ip);
  }

  /* ======================================================
     ADMIN ENDPOINTS
     ====================================================== */

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  async getUsers(
    @Query('role') role?: string,
    @Query('status') status?: string,
    @Query('showDeleted') showDeleted?: string,
  ) {
    return this.usersService.findAll(role, status, showDeleted === 'true');
  }

  @Patch(':id/status')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  async updateUserStatus(
    @Param('id') id: string,
    @Body('status') status: string,
    @CurrentUser() user: any,
    @Ip() ip: string,
  ) {
    return this.usersService.updateStatus(id, status, user.id, ip);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
  async updateUserProfile(
    @Param('id') id: string,
    @Body() updateDto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(id, updateDto);
  }

  @Post('upload-avatar')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './uploads/avatars',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = extname(file.originalname);
        cb(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
      }
    }),
    fileFilter: (req, file, cb) => {
      if (!file.mimetype.match(/\/(jpg|jpeg|png|gif)$/)) {
        return cb(new Error('Only image files are allowed!'), false);
      }
      cb(null, true);
    }
  }))
  async uploadAvatar(
    @CurrentUser() user: any,
    @UploadedFile() file: Express.Multer.File
  ) {
    if (!file) throw new Error('File upload failed');
    // Construct full URL (assuming backend is reachable)
    // Actually, converting to relative path or full URL depends on client.
    // Let's store partial path 'uploads/avatars/filename' and let client prefix it, 
    // OR store full URL if we know the host. Ideally relative is flexible.
    // But usually frontend expects a full URL for NetworkImage.
    // For now, let's assume we return the path and Service handles update.

    // We need to pass the file path to service to update user.
    // Note: 'path' property in file object usually has the full relative/absolute path.
    return this.usersService.updateAvatar(user.id, file.path);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  async deleteUser(@Param('id') id: string, @CurrentUser() user: any, @Ip() ip: string) {
    return this.usersService.remove(id, user.id, ip);
  }
}


