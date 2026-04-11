import { IsNotEmpty, IsString, IsNumber, IsOptional, IsBoolean, IsArray, IsUUID } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateProductDto {
    @IsNotEmpty()
    @IsString()
    name: string;

    @IsNotEmpty()
    @IsString()
    sku: string;

    @IsOptional()
    @IsUUID()
    brandId?: string;

    @IsOptional()
    @IsUUID()
    categoryId: string;

    @IsNotEmpty()
    @IsNumber()
    @Type(() => Number)
    price: number;

    @IsOptional()
    @IsNumber()
    @Type(() => Number)
    mrp?: number;

    @IsOptional()
    @IsString()
    description?: string;

    @IsOptional()
    @IsString()
    currency: string = 'INR';

    @IsOptional()
    @IsString()
    hsn?: string;

    @IsOptional()
    @IsNumber()
    @Type(() => Number)
    gstPercent?: number;

    @IsOptional()
    @IsString()
    material?: string;

    @IsOptional()
    @IsString()
    size?: string;

    @IsOptional()
    @IsString()
    variant?: string;

    @IsOptional()
    @IsString()
    variationGroupId?: string;

    @IsOptional()
    @IsString()
    variationType?: string;

    @IsOptional()
    @IsBoolean()
    isGstInclusive?: boolean = false;

    @IsOptional()
    @IsBoolean()
    isActive?: boolean = true;

    @IsOptional()
    @IsString()
    badge?: string;

    @IsOptional()
    @IsArray()
    @IsString({ each: true })
    images?: string[];

    @IsOptional()
    specifications?: Record<string, any>;
}

export class UpdateProductDto {
    @IsOptional()
    @IsString()
    name?: string;

    @IsOptional()
    @IsString()
    sku?: string;

    @IsOptional()
    @IsUUID()
    brandId?: string;

    @IsOptional()
    @IsUUID()
    categoryId?: string;

    @IsOptional()
    @IsNumber()
    @Type(() => Number)
    price?: number;

    @IsOptional()
    @IsNumber()
    @Type(() => Number)
    mrp?: number;

    @IsOptional()
    @IsString()
    description?: string;

    @IsOptional()
    @IsString()
    hsn?: string;

    @IsOptional()
    @IsNumber()
    @Type(() => Number)
    gstPercent?: number;

    @IsOptional()
    @IsString()
    material?: string;

    @IsOptional()
    @IsString()
    size?: string;

    @IsOptional()
    @IsString()
    variant?: string;

    @IsOptional()
    @IsString()
    variationGroupId?: string;

    @IsOptional()
    @IsString()
    variationType?: string;

    @IsOptional()
    @IsBoolean()
    isGstInclusive?: boolean;

    @IsOptional()
    @IsBoolean()
    isActive?: boolean;

    @IsOptional()
    @IsString()
    badge?: string;

    @IsOptional()
    @IsArray()
    @IsString({ each: true })
    images?: string[];

    @IsOptional()
    specifications?: Record<string, any>;
}
