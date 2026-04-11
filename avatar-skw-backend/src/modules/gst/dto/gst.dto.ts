import { IsBoolean, IsInt, IsOptional, Min, Max } from 'class-validator';

export class CreateGstDto {
    @IsInt()
    @Min(0)
    @Max(100)
    percentage: number;

    @IsBoolean()
    @IsOptional()
    isActive?: boolean;
}

export class UpdateGstDto {
    @IsInt()
    @Min(0)
    @Max(100)
    @IsOptional()
    percentage?: number;

    @IsBoolean()
    @IsOptional()
    isActive?: boolean;
}
