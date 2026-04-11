import { IsEmail, IsOptional, IsPhoneNumber, IsBoolean } from 'class-validator';

export class UpdateContactSettingsDto {
    @IsOptional()
    @IsEmail()
    supportEmail?: string;

    @IsOptional()
    whatsappNumber?: string;

    @IsOptional()
    callNumber?: string;

    @IsOptional()
    @IsBoolean()
    isActive?: boolean;
}
