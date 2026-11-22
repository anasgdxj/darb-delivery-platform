import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class RequestOtpDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  phone!: string;
}

