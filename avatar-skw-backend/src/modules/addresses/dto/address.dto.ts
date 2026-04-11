import { IsString, IsEnum, IsBoolean, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { AddressType } from '../entities/address.entity';

export class CreateAddressDto {
    @ApiProperty({ example: 'John Doe' })
    @IsString()
    name: string;

    @ApiProperty({ example: '123 Main Street' })
    @IsString()
    street: string;

    @ApiProperty({ example: 'New York' })
    @IsString()
    city: string;

    @ApiProperty({ example: 'NY' })
    @IsString()
    state: string;

    @ApiProperty({ example: '10001' })
    @IsString()
    zipCode: string;

    @ApiProperty({ example: '+1234567890' })
    @IsString()
    phone: string;

    @ApiProperty({ enum: AddressType, example: AddressType.HOME })
    @IsEnum(AddressType)
    type: AddressType;

    @ApiProperty({ example: 'Near Park', required: false })
    @IsString()
    @IsOptional()
    landmark?: string;

    @ApiProperty({ example: 'Home', required: false })
    @IsString()
    @IsOptional()
    label?: string;

    @ApiProperty({ example: false, required: false })
    @IsBoolean()
    @IsOptional()
    isDefault?: boolean;
}

export class UpdateAddressDto {
    @ApiProperty({ example: 'John Doe', required: false })
    @IsString()
    @IsOptional()
    name?: string;

    @ApiProperty({ example: '123 Main Street', required: false })
    @IsString()
    @IsOptional()
    street?: string;

    @ApiProperty({ example: 'New York', required: false })
    @IsString()
    @IsOptional()
    city?: string;

    @ApiProperty({ example: 'NY', required: false })
    @IsString()
    @IsOptional()
    state?: string;

    @ApiProperty({ example: '10001', required: false })
    @IsString()
    @IsOptional()
    zipCode?: string;

    @ApiProperty({ example: '+1234567890', required: false })
    @IsString()
    @IsOptional()
    phone?: string;

    @ApiProperty({ enum: AddressType, required: false })
    @IsEnum(AddressType)
    @IsOptional()
    type?: AddressType;

    @ApiProperty({ example: 'Near Park', required: false })
    @IsString()
    @IsOptional()
    landmark?: string;

    @ApiProperty({ example: 'Home', required: false })
    @IsString()
    @IsOptional()
    label?: string;

    @ApiProperty({ example: false, required: false })
    @IsBoolean()
    @IsOptional()
    isDefault?: boolean;
}
