import { IsString, IsOptional, IsBoolean } from 'class-validator';

export class CreateSettingDto {
  @IsString()
  key: string;

  @IsString()
  value: string;

  @IsBoolean()
  @IsOptional()
  isSecret?: boolean;
}

export class UpdateSettingDto {
  @IsString()
  value: string;
}


