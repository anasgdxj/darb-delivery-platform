import { Locale } from '@prisma/client';
import { IsEnum, IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class VerifyOtpDto {
  @IsString()
  @MaxLength(20)
  phone!: string;

  @IsString()
  @Matches(/^\d{6}$/, { message: 'الرمز يجب أن يكون 6 أرقام' })
  code!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsEnum(Locale)
  locale?: Locale;
}

