import { Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { UpdateProfileDto, CreateAdminDto } from './dto/users.dto';
import { AppException } from '../../common/exceptions/app.exception';
import { UserRole, UserStatus } from './entities/user.entity';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { AuditLogActionType, AuditLogStatus } from '../audit-logs/entities/audit-log.entity';
import { WhatsAppService } from '../whatsapp/whatsapp.service';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private auditLogsService: AuditLogsService,
    private readonly whatsAppService: WhatsAppService,
  ) { }

  async findById(id: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async updateProfile(userId: string, updateDto: UpdateProfileDto): Promise<User> {
    const user = await this.findById(userId);
    const oldStatus = user.status;

    // Explicitly handle discountPercentage if present
    if (updateDto.discountPercentage !== undefined) {
      user.discountPercentage = updateDto.discountPercentage;
    }

    Object.assign(user, updateDto);
    const saved = await this.userRepository.save(user);

    // Send WhatsApp Notification for Dealers if status changed
    if (saved.role === UserRole.DEALER) {
      // Treat ACTIVE and APPROVED as "Approved State" for notifications
      const isNowApproved = (saved.status === UserStatus.APPROVED || saved.status === UserStatus.ACTIVE);
      const wasApproved = (oldStatus === UserStatus.APPROVED || oldStatus === UserStatus.ACTIVE);

      if (isNowApproved && !wasApproved) {
        await this.whatsAppService.sendDealerApprovalNotification(saved);
      } else if (saved.status === UserStatus.REJECTED && oldStatus !== UserStatus.REJECTED) {
        await this.whatsAppService.sendDealerRejectionNotification(saved);
      }
    }

    return saved;
  }

  async updateAvatar(userId: string, filePath: string): Promise<User> {
    const user = await this.findById(userId);
    // Normalize path to be URL friendly (replace backslashes)
    // Also, ensure it starts with / (or full URL)
    // Assuming we serve 'uploads' as static, URL is /uploads/avatars/filename
    const relativePath = filePath.replace(/\\/g, '/').split('uploads/')[1];
    const fullUrl = `${process.env.BACKEND_URL || 'http://192.168.31.75:3000'}/uploads/${relativePath}`;

    user.avatar = fullUrl;
    return this.userRepository.save(user);
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string): Promise<{ message: string }> {
    // Load user with passwordHash (select: false by default so need direct query)
    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: ['id', 'passwordHash'],
    });
    if (!user) throw new NotFoundException('User not found');

    const bcrypt = await import('bcrypt');
    const isMatch = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    const newHash = await bcrypt.hash(newPassword, 12);
    await this.userRepository.update(userId, { passwordHash: newHash });

    return { message: 'Password changed successfully' };
  }

  async getProfile(userId: string) {
    const user = await this.findById(userId);
    return this.sanitizeUser(user);
  }

  async findAll(role?: string, status?: string, showDeleted: boolean = false) {
    const query = this.userRepository.createQueryBuilder('user')
      .leftJoinAndSelect('user.dealerTier', 'dealerTier');

    // Only filter out deleted users if showDeleted is false
    if (!showDeleted) {
      query.where('user.status != :deletedStatus', { deletedStatus: UserStatus.DELETED });
    }

    if (role) {
      query.andWhere('user.role = :role', { role });
    }

    if (status) {
      query.andWhere('user.status = :status', { status });
    }

    const users = await query.getMany();
    return users.map(user => this.sanitizeUser(user));
  }

  async updateStatus(id: string, status: string, adminId?: string, ip?: string): Promise<User> {
    const user = await this.findById(id);
    const oldStatus = user.status;
    user.status = status as any;
    const saved = await this.userRepository.save(user);

    if (adminId) {
      this.auditLogsService.logAction(
        adminId,
        AuditLogActionType.USER,
        `User ${saved.name} ${status}`,
        `Updated status from ${oldStatus} to ${status}`,
        ip
      );
    }

    // Send WhatsApp Notification for Dealers
    if (saved.role === UserRole.DEALER) {
      if (status === UserStatus.APPROVED && oldStatus !== UserStatus.APPROVED) {
        await this.whatsAppService.sendDealerApprovalNotification(saved);
      } else if (status === UserStatus.REJECTED && oldStatus !== UserStatus.REJECTED) {
        await this.whatsAppService.sendDealerRejectionNotification(saved);
      }
    }

    return saved;
  }

  async remove(id: string, adminId?: string, ip?: string): Promise<void> {
    const user = await this.findById(id);

    // Soft delete: Update status to DELETED instead of removing
    user.status = UserStatus.DELETED;
    await this.userRepository.save(user);

    if (adminId) {
      this.auditLogsService.logAction(
        adminId,
        AuditLogActionType.DELETE,
        `Deleted User ${user.name}`,
        `Soft-deleted user from system (Phone: ${user.phone})`,
        ip
      );
    }
  }

  // --- Admin Management (Super Admin only checks should be in Controller/Guard) ---

  async createAdmin(createDto: CreateAdminDto, adminId?: string, ip?: string): Promise<User> {
    // Check duplicates
    const existing = await this.userRepository.findOne({ where: { phone: createDto.phone } });
    if (existing) {
      throw new AppException('USER_EXISTS', 'User with this phone already exists');
    }

    // Hash password
    const bcrypt = await import('bcrypt');
    const hashedPassword = await bcrypt.hash(createDto.password, 12);

    const admin = this.userRepository.create({
      ...createDto,
      passwordHash: hashedPassword,
      role: UserRole.ADMIN,
      status: UserStatus.ACTIVE,
    } as unknown as User);

    const saved = await this.userRepository.save(admin);

    if (adminId) {
      this.auditLogsService.logAction(
        adminId,
        AuditLogActionType.USER,
        `Created Admin ${saved.name}`,
        `Granted admin access`,
        ip
      );
    }

    return saved;
  }

  async updatePermissions(id: string, permissions: Record<string, string[]>, adminId?: string, ip?: string): Promise<User> {
    const user = await this.findById(id);
    if (user.role !== UserRole.ADMIN) {
      throw new AppException('INVALID_ROLE', 'Can only set permissions for Admins');
    }
    user.permissions = permissions;
    const saved = await this.userRepository.save(user);

    if (adminId) {
      this.auditLogsService.logAction(
        adminId,
        AuditLogActionType.USER,
        `Updated Permissions for ${saved.name}`,
        `Modified access controls`,
        ip
      );
    }
    return saved;
  }

  async getAdmins(): Promise<User[]> {
    const admins = await this.userRepository.find({
      where: { role: UserRole.ADMIN },
      order: { createdAt: 'DESC' }
    });
    return admins.map(u => this.sanitizeUser(u) as unknown as User);
  }

  private sanitizeUser(user: User) {
    const { passwordHash, ...sanitized } = user;
    return sanitized;
  }
}


