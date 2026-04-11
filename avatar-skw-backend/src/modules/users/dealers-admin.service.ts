import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Not } from 'typeorm';
import { User, UserStatus, UserRole } from './entities/user.entity';
import { ApproveDealerDto, RejectDealerDto } from './dto/dealers-admin.dto';
import { UpdateDealerProfileDto } from './dto/update-dealer-profile.dto';
import { WhatsAppService } from '../whatsapp/whatsapp.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/entities/notification.entity';
import { AppException } from '../../common/exceptions/app.exception';

@Injectable()
export class DealersAdminService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private whatsappService: WhatsAppService,
    private notificationsService: NotificationsService,
  ) { }

  async getPendingApplications() {
    return this.userRepository.find({
      where: {
        role: UserRole.DEALER,
        status: UserStatus.PENDING,
      },
      relations: ['dealerTier'],
      order: { createdAt: 'DESC' },
    });
  }

  async getDealer(id: string, includeDeleted: boolean = false) {
    const where: any = {
      id,
      role: UserRole.DEALER,
    };

    if (!includeDeleted) {
      where.status = Not(UserStatus.DELETED);
    }

    const dealer = await this.userRepository.findOne({
      where,
      relations: ['dealerTier'],
    });

    if (!dealer) {
      throw new NotFoundException('Dealer not found');
    }

    return dealer;
  }

  async approveDealer(id: string, approveDto: ApproveDealerDto) {
    const dealer = await this.getDealer(id);

    if (dealer.status !== UserStatus.PENDING) {
      throw new AppException(
        'INVALID_STATUS',
        'Dealer is not in pending status',
      );
    }

    dealer.status = UserStatus.APPROVED;
    const updatedDealer = await this.userRepository.save(dealer);

    // Optional WhatsApp notification
    try {
      await this.whatsappService.sendDealerApprovalNotification(dealer);
    } catch (error) {
      // Log but don't fail the approval
      console.error('Failed to send WhatsApp notification:', error);
    }

    // In-App Notification for Real-time Update
    try {
      await this.notificationsService.create(
        dealer.id,
        'Account Approved',
        'Your dealer account has been approved! You can now access dealer prices and features.',
        NotificationType.ACCOUNT_UPDATE,
        { status: UserStatus.APPROVED }
      );
    } catch (e) {
      console.error('Failed to send in-app notification', e);
    }

    return updatedDealer;
  }

  async rejectDealer(id: string, rejectDto: RejectDealerDto) {
    const dealer = await this.getDealer(id);

    if (dealer.status !== UserStatus.PENDING) {
      throw new AppException(
        'INVALID_STATUS',
        'Dealer is not in pending status',
      );
    }

    dealer.status = UserStatus.REJECTED;
    const saved = await this.userRepository.save(dealer);

    try {
      await this.whatsappService.sendDealerRejectionNotification(dealer);
    } catch (e) {
      console.error('Failed to send rejection notification', e);
    }

    // In-App Notification
    try {
      await this.notificationsService.create(
        dealer.id,
        'Account Rejected',
        'Your dealer account application has been rejected.',
        NotificationType.ACCOUNT_UPDATE,
        { status: UserStatus.REJECTED }
      );
    } catch (e) {
      console.error('Failed to send in-app notification', e);
    }

    return saved;
  }

  async updateDealerProfile(id: string, dto: UpdateDealerProfileDto) {
    const dealer = await this.getDealer(id, true);

    const oldStatus = dealer.status;

    // Check for duplicate phone
    if (dto.phone && dto.phone !== dealer.phone) {
      const existingPhone = await this.userRepository.findOne({
        where: { phone: dto.phone, id: Not(id) },
      });
      if (existingPhone) {
        throw new AppException('DUPLICATE_PHONE', 'Phone number is already used by another user');
      }
    }

    // Check for duplicate email
    if (dto.email && dto.email !== dealer.email) {
      const existingEmail = await this.userRepository.findOne({
        where: { email: dto.email, id: Not(id) },
      });
      if (existingEmail) {
        throw new AppException('DUPLICATE_EMAIL', 'Email is already used by another user');
      }
    }

    Object.assign(dealer, dto);
    const saved = await this.userRepository.save(dealer);

    // Send WhatsApp Notification if status changed
    // Treat ACTIVE and APPROVED as "Approved State"
    const isNowApproved = (saved.status === UserStatus.APPROVED || saved.status === UserStatus.ACTIVE);
    const wasApproved = (oldStatus === UserStatus.APPROVED || oldStatus === UserStatus.ACTIVE);

    if (isNowApproved && !wasApproved) {
      try {
        await this.whatsappService.sendDealerApprovalNotification(saved);
      } catch (e) {
        console.error('Failed to send approval notification', e);
      }
      // In-App Notification
      try {
        await this.notificationsService.create(
          saved.id,
          'Account Approved',
          'Your dealer account has been approved!',
          NotificationType.ACCOUNT_UPDATE,
          { status: saved.status }
        );
      } catch (e) {
        console.error('Failed to send in-app notification', e);
      }

    } else if (saved.status === UserStatus.REJECTED && oldStatus !== UserStatus.REJECTED) {
      try {
        await this.whatsappService.sendDealerRejectionNotification(saved);
      } catch (e) {
        console.error('Failed to send rejection notification', e);
      }
      // In-App Notification
      try {
        await this.notificationsService.create(
          saved.id,
          'Account Rejected',
          'Your dealer account application has been rejected.',
          NotificationType.ACCOUNT_UPDATE,
          { status: saved.status }
        );
      } catch (e) {
        console.error('Failed to send in-app notification', e);
      }
    }

    return saved;
  }
}


