import { IsNotEmpty, IsString, IsOptional, IsBoolean } from 'class-validator';

export class CreateBrandDto {
    @IsNotEmpty()
    @IsString()
    name: string;

    @IsOptional()
    @IsString()
    logo?: string;

    @IsOptional()
    @IsBoolean()
    isActive?: boolean;
}

export class UpdateBrandDto {
    @IsOptional()
    @IsString()
    name?: string;

    @IsOptional()
    @IsString()
    logo?: string;

    @IsOptional()
    @IsBoolean()
    isActive?: boolean;
}
