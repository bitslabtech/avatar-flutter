import {
  IsArray,
  IsObject,
  IsString,
  IsInt,
  IsOptional,
  ValidateNested,
  Min,
  IsUUID,
  IsNumber,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class CreateOrderItemDto {
  @ApiProperty({ example: '8d9b0f4d-1234-4c2f-9b0b-123456789abc' })
  @IsString()
  productId: string;

  @ApiProperty({ example: 2, minimum: 1 })
  @IsInt()
  @Min(1)
  qty: number;
}

export class AddressDto {
  @ApiProperty({ example: '123 MG Road', required: false })
  @IsString()
  @IsOptional()
  street?: string;

  @ApiProperty({ example: 'Bangalore' })
  @IsString()
  city: string;

  @ApiProperty({ example: 'KA' })
  @IsString()
  state: string;

  @ApiProperty({ example: '560001' })
  @IsString()
  zipCode: string;

  @ApiProperty({ example: 'India', required: false })
  @IsString()
  @IsOptional()
  country?: string;

  @ApiProperty({ example: 'John Doe' })
  @IsString()
  name: string;

  @ApiProperty({ example: '9999000004' })
  @IsString()
  phone: string;

  @ApiProperty({ example: 'Near Park', required: false })
  @IsString()
  @IsOptional()
  landmark?: string;

  @ApiProperty({ example: 'Home', required: false })
  @IsString()
  @IsOptional()
  label?: string;

  @ApiProperty({ example: 'home', required: false })
  @IsString()
  @IsOptional()
  type?: string;
}

export class CreateOrderDto {
  @ApiProperty({ type: [CreateOrderItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];

  @ApiProperty({ type: () => AddressDto, required: false })
  @IsObject()
  @IsOptional()
  @ValidateNested()
  @Type(() => AddressDto)
  address?: AddressDto;

  @ApiProperty({ example: 'blue-dart', required: false })
  @IsString()
  @IsOptional()
  courierPreference?: string;
}

export class UpdateOrderStatusDto {
  @ApiProperty({ example: 'dispatched' })
  @IsString()
  status: string;

  @ApiProperty({ example: 'Shipped via Bluedart', required: false })
  @IsString()
  @IsOptional()
  notes?: string;

  @ApiProperty({ example: '2023-10-25T10:00:00Z', required: false })
  @IsString()
  @IsOptional()
  estimatedDeliveryDate?: string; // Using string for DateString input

  @ApiProperty({ example: 'FedEx', required: false })
  @IsString()
  @IsOptional()
  courierProvider?: string;

  @ApiProperty({ example: 'TRACK123AC', required: false })
  @IsString()
  @IsOptional()
  trackingNumber?: string;

  @ApiProperty({ example: 5000, description: 'Override shipping fee in paise (null = use standard charge)', required: false })
  @IsOptional()
  @IsNumber()
  shippingOverridePaise?: number | null;
}



export class CreateOrderOnBehalfDto {
  @ApiProperty({ example: '8d9b0f4d-1234-4c2f-9b0b-123456789abc' })
  @IsUUID()
  userId: string;

  @ApiProperty({ type: [CreateOrderItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];

  @ApiProperty({ example: 'COD', required: false })
  @IsString()
  @IsOptional()
  @IsOptional()
  paymentMethod?: string;

  @ApiProperty({ type: () => AddressDto, required: false })
  @IsObject()
  @IsOptional()
  @ValidateNested()
  @Type(() => AddressDto)
  address?: AddressDto;

  @ApiProperty({ example: true, required: false })
  @IsOptional()
  saveAddress?: boolean;
}

export class ConfirmOrderDto {
  @ApiProperty({ type: () => AddressDto })
  @IsObject()
  @ValidateNested()
  @Type(() => AddressDto)
  address: AddressDto;

  @ApiProperty({ example: 'cod' })
  @IsString()
  paymentMethod: string;
}
