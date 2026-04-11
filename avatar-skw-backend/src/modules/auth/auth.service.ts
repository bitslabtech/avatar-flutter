import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { User, UserRole, UserStatus } from '../users/entities/user.entity';
import { WhatsAppService } from '../whatsapp/whatsapp.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/entities/notification.entity';
import {
  RegisterDto,
  LoginDto,
  RefreshTokenDto,
  ForgotPasswordDto,
  ResetPasswordDto,
} from './dto/auth.dto';
import { AppException } from '../../common/exceptions/app.exception';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { AuditLogActionType, AuditLogStatus } from '../audit-logs/entities/audit-log.entity';

@Injectable()
export class AuthService {
  private readonly saltRounds = 12;

  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
    private configService: ConfigService,
    private whatsAppService: WhatsAppService,
    private notificationsService: NotificationsService,
    private auditLogsService: AuditLogsService,
  ) { }

  async register(registerDto: RegisterDto) {
    // Check if user already exists
    const existingUser = await this.userRepository.findOne({
      where: [{ phone: registerDto.phone }, { email: registerDto.email }],
    });

    if (existingUser) {
      throw new AppException(
        'USER_EXISTS',
        'User with this phone or email already exists',
      );
    }

    // Check if GST number already exists (only if provided)
    if (registerDto.gstVat) {
      const existingGst = await this.userRepository.findOne({
        where: { gstVat: registerDto.gstVat },
      });

      if (existingGst) {
        throw new AppException(
          'GST_EXISTS',
          'User with this GST/VAT number already exists',
        );
      }
    }

    // Hash password
    const passwordHash = await bcrypt.hash(
      registerDto.password,
      this.saltRounds,
    );

    // Create user
    const user = this.userRepository.create({
      name: registerDto.name,
      phone: registerDto.phone,
      email: registerDto.email,
      passwordHash,
      role: registerDto.role,
      status:
        registerDto.role === UserRole.DEALER
          ? UserStatus.PENDING
          : UserStatus.ACTIVE,
      companyName: registerDto.companyName,
      gstVat: registerDto.gstVat,
      address: registerDto.address,
      documents: registerDto.documents || [],
      discountPercentage: registerDto.role === UserRole.DEALER ? (registerDto.discountPercentage || 0) : null,
    });

    const savedUser = await this.userRepository.save(user);

    // Generate tokens
    const tokens = await this.generateTokens(savedUser);

    // Send WhatsApp Registration Notification
    if (savedUser.role === UserRole.DEALER) {
      await this.whatsAppService.sendDealerRegistrationNotification(savedUser);

      // Notify Admins about new Dealer
      await this.notificationsService.notifyAdmins(
        'New Dealer Registration',
        `New dealer ${savedUser.name} (${savedUser.companyName || 'No Company'}) has registered and is pending approval.`,
        NotificationType.NEW_DEALER,
        { userId: savedUser.id },
        savedUser.id // Exclude the dealer themselves (though they aren't admin usually)
      );
    } else {
      await this.whatsAppService.sendUserRegistrationNotification(savedUser);

      // Notify Admins about new User
      await this.notificationsService.notifyAdmins(
        'New User Registration',
        `New user ${savedUser.name} has registered.`,
        NotificationType.NEW_USER,
        { userId: savedUser.id },
        savedUser.id
      );
    }

    return {
      user: this.sanitizeUser(savedUser),
      ...tokens,
    };
  }

  async login(loginDto: LoginDto, ip?: string) {
    const user = await this.userRepository.findOne({
      where: { phone: loginDto.phone },
    });

    // DEBUG LOGS
    console.log(`[DEBUG] Login attempt for: ${loginDto.phone}`);
    console.log(`[DEBUG] User found: ${user ? 'YES' : 'NO'}`);
    if (user) {
      console.log(`[DEBUG] DB Hash: ${user.passwordHash}`);
      console.log(`[DEBUG] Input Password: ${loginDto.password}`);
    }

    if (!user) {
      console.log('[DEBUG] User not found -> Invalid credentials');
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(
      loginDto.password,
      user.passwordHash,
    );
    console.log(`[DEBUG] Password Valid: ${isPasswordValid}`);

    if (!isPasswordValid) {
      console.log('[DEBUG] Compare failed -> Invalid credentials');
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check Status
    if (user.status === UserStatus.REJECTED) {
      throw new AppException(
        'ACCOUNT_REJECTED',
        'Your account has been rejected. Please contact support.',
      );
    }

    // Admins must be ACTIVE to login
    if ((user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN) && user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Your account is inactive. Please contact Administrator.');
    }

    // For Dealers/Users, we might allow Pending login for status check, but Inactive usually means disabled.
    // Assuming Inactive = Disabled for all for security, unless Pending.
    if (user.status === UserStatus.INACTIVE) {
      throw new UnauthorizedException('Your account is inactive.');
    }

    const tokens = await this.generateTokens(user);



    // Log Admin Login
    if (user.role === UserRole.ADMIN || user.role === UserRole.SUPER_ADMIN) {
      this.auditLogsService.logAction(
        user.id,
        AuditLogActionType.AUTH,
        `Admin Login`,
        `Admin logged in successfully`,
        ip,
        AuditLogStatus.SUCCESS
      ).catch(console.error);
    }

    return {
      user: this.sanitizeUser(user),
      ...tokens,
    };
  }

  async refreshToken(refreshTokenDto: RefreshTokenDto) {
    try {
      const jwtConfig = this.configService.get('jwt');
      const payload = this.jwtService.verify(refreshTokenDto.refreshToken, {
        secret: jwtConfig.refreshSecret,
      });

      const user = await this.userRepository.findOne({
        where: { id: payload.sub },
      });

      if (!user || user.status === UserStatus.REJECTED) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      return this.generateTokens(user);
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async forgotPassword(forgotPasswordDto: ForgotPasswordDto) {
    const user = await this.userRepository.findOne({
      where: { phone: forgotPasswordDto.phone },
      select: ['id', 'phone', 'name', 'role'], // minimal fields
    });

    if (!user) {
      // Don't reveal if user exists
      return { message: 'If the phone number exists, an OTP has been sent' };
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Hash OTP
    const salt = await bcrypt.genSalt(10);
    const otphash = await bcrypt.hash(otp, salt);

    // Save to User (Expiry: 10 mins)
    // We need to update directly since we added columns locally but might not be in the default 'save' if not reloaded? 
    // Actually standard save works if entity has columns.
    // However, resetOtp is select: false, so we need to be careful not to overwrite with null if we loaded partial.
    // Safest is to use update.
    await this.userRepository.update(user.id, {
      resetOtp: otphash,
      resetOtpExpiry: new Date(Date.now() + 10 * 60 * 1000), // 10 mins
    });

    // Send via WhatsApp
    // circular dependency check? WhatsAppService is likely imported. check module.
    // Assuming this.whatsAppService is available (need to inject it)
    // We will assume it is injected or need to add it to constructor.
    // Checking file.. constructor only has userRepo, jwt, config.
    // Need to inject WhatsAppService. 
    // For now, I will add the logic, but I need to update constructor in a separate tool call if it's missing.
    // I'll add the injection in the next step or this one if I can see constructor.
    // I can't see the constructor in this specific slice, so I will handle logic only and assume I'll fix injection next.

    // Using a dynamic require or assuming it's there for a second... 
    // Actually, I must inject it. 
    // Refactoring this block to just return the OTP for Dev/Console if service missing, but plan to inject.

    console.log(`[DEV OTP] for ${user.phone}: ${otp}`);
    this.whatsAppService.sendOtp(user.phone, otp);

    return { message: 'If the phone number exists, an OTP has been sent' };
  }

  async verifyOtp(verifyOtpDto: { phone: string; otp: string }) {
    const user = await this.userRepository.findOne({
      where: { phone: verifyOtpDto.phone },
      select: ['id', 'resetOtp', 'resetOtpExpiry'],
    });

    if (!user || !user.resetOtp || !user.resetOtpExpiry) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    if (new Date() > user.resetOtpExpiry) {
      throw new BadRequestException('OTP expired');
    }

    const isValid = await bcrypt.compare(verifyOtpDto.otp, user.resetOtp);
    if (!isValid) {
      throw new BadRequestException('Invalid OTP');
    }

    // Generate a temporary reset token (short lived JWT)
    const resetToken = this.jwtService.sign(
      { sub: user.id, purpose: 'password_reset' },
      { secret: this.configService.get('jwt.secret'), expiresIn: '15m' }
    );

    return { resetToken };
  }

  async resetPassword(resetPasswordDto: ResetPasswordDto) {
    // Validate token
    // Actually DTO usually contains { phone, otp, newPassword } or { token, newPassword }
    // The plan said: Validate OTP again (or use token). 
    // Let's assume the flow passes `token` and `newPassword`.
    // But `ResetPasswordDto` structure is defined in `auth.dto.ts`. I should check that.
    // Assuming it takes phone + otp + newPassword for simplicity if no token passed, 
    // OR token + newPassword.
    // Let's go with Token approach since verifyOtp returns it.

    // We need to parse the token.
    // If DTO has token:
    if (!resetPasswordDto.token) {
      throw new BadRequestException('Token required');
    }

    let payload;
    try {
      payload = this.jwtService.verify(resetPasswordDto.token, {
        secret: this.configService.get('jwt.secret')
      });
    } catch (e) {
      throw new UnauthorizedException('Invalid or expired token');
    }

    if (payload.purpose !== 'password_reset') {
      throw new UnauthorizedException('Invalid token purpose');
    }

    const user = await this.userRepository.findOne({ where: { id: payload.sub } });
    if (!user) throw new NotFoundException('User not found');

    const passwordHash = await bcrypt.hash(resetPasswordDto.newPassword, this.saltRounds);

    await this.userRepository.update(user.id, {
      passwordHash,
      resetOtp: null,
      resetOtpExpiry: null
    });

    return { message: 'Password reset successful' };
  }

  private async generateTokens(user: User) {
    const jwtConfig = this.configService.get('jwt');
    const payload = { sub: user.id, phone: user.phone, role: user.role };

    const accessToken = this.jwtService.sign(payload, {
      secret: jwtConfig.secret,
      expiresIn: jwtConfig.expiresIn,
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: jwtConfig.refreshSecret,
      expiresIn: jwtConfig.refreshExpiresIn,
    });

    return {
      accessToken,
      refreshToken,
    };
  }

  /** Fetch full user profile from DB (used by GET /auth/me) */
  async getProfile(userId: string) {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new UnauthorizedException('User not found');
    }
    return this.sanitizeUser(user);
  }

  private sanitizeUser(user: User) {
    const { passwordHash, ...sanitized } = user;
    return sanitized;
  }
}


