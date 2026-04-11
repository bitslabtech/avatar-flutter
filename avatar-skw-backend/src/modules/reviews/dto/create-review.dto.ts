import { IsNotEmpty, IsNumber, IsString, Min, Max, IsOptional, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateReviewDto {
    @ApiProperty({ example: 'product-uuid' })
    @IsNotEmpty()
    @IsUUID()
    productId: string;

    @ApiProperty({ example: 4.5 })
    @IsNotEmpty()
    @IsNumber()
    @Min(1)
    @Max(5)
    rating: number;

    @ApiProperty({ example: 'Great product!' })
    @IsOptional()
    @IsString()
    comment?: string;
}
