import { IsString, IsEmail, IsOptional, IsObject, ValidateNested, MinLength } from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

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

export class UpdateProfileDto {
  @ApiProperty({ example: 'John Doe', required: false })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({ example: 'john@example.com', required: false })
  @IsEmail()
  @IsOptional()
  @Transform(({ value }) => value === '' ? undefined : value)
  email?: string;

  @ApiProperty({ example: '9999999999', required: false })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiProperty({ example: 'active', required: false })
  @IsString()
  @IsOptional()
  status?: string;

  @ApiProperty({ type: () => AddressDto, required: false })
  @IsObject()
  @IsOptional()
  @ValidateNested()
  @Type(() => AddressDto)
  address?: AddressDto;

  @ApiProperty({ example: 15.0, required: false })
  @ApiProperty({ example: 15.0, required: false })
  @IsOptional()
  discountPercentage?: number;
}

export class CreateAdminDto {
  @ApiProperty({ example: 'Admin User' })
  @IsString()
  name: string;

  @ApiProperty({ example: 'admin@avatar.com', required: false })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({ example: '9988776655' })
  @IsString()
  phone: string;

  @ApiProperty({ example: 'SecretValid123!' })
  @IsString()
  password: string;

  @ApiProperty({ example: { orders: ['read', 'update'] }, required: false })
  @IsOptional()
  permissions?: Record<string, string[]>;
}

export class UpdateAdminPermissionsDto {
  @ApiProperty({ example: { orders: ['read', 'update'] } })
  @IsObject()
  permissions: Record<string, string[]>;
}

export class ChangePasswordDto {
  @ApiProperty({ example: 'CurrentPass@123' })
  @IsString()
  currentPassword: string;

  @ApiProperty({ example: 'NewPass@456' })
  @IsString()
  @MinLength(8)
  newPassword: string;
}


