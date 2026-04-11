import { IsString, IsOptional, IsUUID } from 'class-validator';

export class ApproveDealerDto {
  @IsString()
  @IsOptional()
  notes?: string;
}

export class RejectDealerDto {
  @IsString()
  @IsOptional()
  reason?: string;
}


