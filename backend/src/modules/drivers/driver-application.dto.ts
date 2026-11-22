import { IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class DriverApplicationDto {
  @IsUUID() cityId!: string;
  @IsOptional() @IsString() @MaxLength(40) vehicleType?: string;
}
