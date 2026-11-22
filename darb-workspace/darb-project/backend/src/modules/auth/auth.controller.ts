import { Body, Controller, Get, HttpCode, HttpStatus, Patch, Post, UseGuards } from '@nestjs/common';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { Locale } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AuthService } from './auth.service';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
class GoogleSignInDto { @IsString() @MinLength(20) @MaxLength(4096) idToken!: string; @IsOptional() @IsIn(['ar','en','tr']) locale?: string; }
class LogoutDto { @IsOptional() @IsString() refreshToken?: string; }
class UpdateProfileDto { @IsOptional() @IsString() @MaxLength(120) name?: string; @IsOptional() @IsIn(['ar','en','tr']) locale?: Locale; }
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}
  @Post('otp/request') @HttpCode(HttpStatus.OK) requestOtp(@Body() dto: RequestOtpDto) { return this.auth.requestOtp(dto.phone); }
  @Post('otp/verify') @HttpCode(HttpStatus.OK) verifyOtp(@Body() dto: VerifyOtpDto) { return this.auth.verifyOtp(dto); }
  @Post('google') @HttpCode(HttpStatus.OK) google(@Body() dto: GoogleSignInDto) { return this.auth.googleSignIn(dto.idToken, dto.locale); }
  @Post('refresh') @HttpCode(HttpStatus.OK) refresh(@Body() dto: RefreshTokenDto) { return this.auth.refresh(dto.refreshToken); }
  @Post('logout') @HttpCode(HttpStatus.OK) logout(@Body() dto: LogoutDto) { return this.auth.logout(dto.refreshToken); }
  @Get('me') @UseGuards(JwtAuthGuard) me(@CurrentUser() user: { id: string }) { return this.auth.me(user.id); }
  @Patch('me') @UseGuards(JwtAuthGuard) updateMe(@CurrentUser() user: { id: string }, @Body() dto: UpdateProfileDto) { return this.auth.updateProfile(user.id, dto); }
}
