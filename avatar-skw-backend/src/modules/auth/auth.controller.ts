import {
  Controller,
  Post,
  Body,
  Get,
  UseGuards,
  HttpCode,
  HttpStatus,
  Ip,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import {
  RegisterDto,
  LoginDto,
  RefreshTokenDto,
  ForgotPasswordDto,
  ResetPasswordDto,
} from './dto/auth.dto';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import {
  ApiBearerAuth,
  ApiTags,
  ApiOperation,
  ApiBody,
  ApiOkResponse,
} from '@nestjs/swagger';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) { }

  @Public()
  @Post('register')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Register a new user (consumer or dealer)' })
  @ApiBody({
    type: RegisterDto,
    examples: {
      consumer: {
        summary: 'Consumer',
        value: {
          name: 'John Doe',
          phone: '9999000005',
          email: 'john@example.com',
          password: 'Password@123',
          role: 'consumer',
        },
      },
      dealer: {
        summary: 'Dealer',
        value: {
          name: 'Dealer User',
          phone: '9999000006',
          email: 'dealer@example.com',
          password: 'Password@123',
          role: 'dealer',
          companyName: 'Dealer Co',
          gstVat: '29ABCDE1234F1Z5',
          address: { city: 'Bangalore', state: 'KA', zipCode: '560001' },
          documents: ['https://example.com/doc1.pdf'],
        },
      },
    },
  })
  async register(@Body() registerDto: RegisterDto) {
    return this.authService.register(registerDto);
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Login with phone and password' })
  @ApiBody({
    type: LoginDto,
    examples: {
      default: {
        summary: 'Login with phone/password',
        value: { phone: '9999000004', password: 'Password@123' },
      },
    },
  })
  @ApiOkResponse({
    description: 'Returns user and tokens',
    schema: {
      example: {
        user: {
          id: 'uuid',
          phone: '9999000004',
          role: 'consumer',
          status: 'active',
        },
        accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        refreshToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
      },
    },
  })
  async login(@Body() loginDto: LoginDto, @Ip() ip: string) {
    return this.authService.login(loginDto, ip);
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh access token' })
  async refresh(@Body() refreshTokenDto: RefreshTokenDto) {
    return this.authService.refreshToken(refreshTokenDto);
  }

  @Public()
  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request password reset (stub)' })
  async forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto) {
    return this.authService.forgotPassword(forgotPasswordDto);
  }

  @Public()
  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify OTP' })
  async verifyOtp(@Body() verifyOtpDto: { phone: string; otp: string }) { // Using inline or import DTO if added to imports
    return this.authService.verifyOtp(verifyOtpDto);
  }

  @Public()
  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reset password (stub)' })
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    return this.authService.resetPassword(resetPasswordDto);
  }

  @Get('me')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get current user profile (full DB record)' })
  async getMe(@CurrentUser() user: any) {
    // Return full DB user (not just JWT payload) so fields like
    // discountPercentage, companyName, address are always up-to-date
    return this.authService.getProfile(user.id);
  }
}


