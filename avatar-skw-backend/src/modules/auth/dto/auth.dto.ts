import {
  IsString,
  IsEmail,
  IsOptional,
  IsEnum,
  MinLength,
  IsArray,
  IsObject,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { UserRole } from '../../users/entities/user.entity';
import { ApiProperty } from '@nestjs/swagger';

// Define AddressDto first to avoid ReferenceError
export class AddressDto {
  @ApiProperty({ example: '123 MG Road', required: false })
  @IsString()
  @IsOptional()
  street?: string;

  @ApiProperty({ example: 'Bangalore', required: false })
  @IsString()
  @IsOptional()
  city?: string;

  @ApiProperty({ example: 'KA', required: false })
  @IsString()
  @IsOptional()
  state?: string;

  @ApiProperty({ example: '560001', required: false })
  @IsString()
  @IsOptional()
  zipCode?: string;

  @ApiProperty({ example: 'India', required: false })
  @IsString()
  @IsOptional()
  country?: string;
}

export class RegisterDto {
  @ApiProperty({ example: 'John Doe' })
  @IsString()
  name: string;

  @ApiProperty({ example: '9999000005' })
  @IsString()
  phone: string;

  @ApiProperty({ example: 'john@example.com', required: false })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({ example: 'Password@123' })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiProperty({ enum: UserRole, example: UserRole.CONSUMER })
  @IsEnum(UserRole)
  role: UserRole;

  // Dealer-specific fields
  @ApiProperty({ example: 'Dealer Co', required: false })
  @IsString()
  @IsOptional()
  companyName?: string;

  @ApiProperty({ example: '29ABCDE1234F1Z5', required: false })
  @IsString()
  @IsOptional()
  gstVat?: string;

  @ApiProperty({ example: 10.5, required: false })
  @IsOptional()
  discountPercentage?: number;

  @ApiProperty({ type: () => AddressDto, required: false })
  @IsObject()
  @IsOptional()
  @ValidateNested()
  @Type(() => AddressDto)
  address?: AddressDto;

  @ApiProperty({ type: [String], required: false, example: ['https://.../doc1.pdf'] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  documents?: string[];
}

export class LoginDto {
  @ApiProperty({ example: '9999000005' })
  @IsString()
  phone: string;

  @ApiProperty({ example: 'Password@123' })
  @IsString()
  password: string;
}

export class RefreshTokenDto {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' })
  @IsString()
  refreshToken: string;
}

export class ForgotPasswordDto {
  @ApiProperty({ example: '9999000005' })
  @IsString()
  phone: string;
}

export class VerifyOtpDto {
  @ApiProperty({ example: '9999000005' })
  @IsString()
  phone: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  otp: string;
}

export class ResetPasswordDto {
  @ApiProperty({ example: 'reset-token-here' })
  @IsString()
  token: string;

  @ApiProperty({ example: 'NewPassword@123' })
  @IsString()
  @MinLength(8)
  newPassword: string;
}


