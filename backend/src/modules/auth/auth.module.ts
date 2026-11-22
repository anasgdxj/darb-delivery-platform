import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { OtpService } from './otp.service';
import { SMS_PROVIDER, SmsProvider } from './sms/sms.provider';
import { ConsoleSmsProvider, HttpSmsProvider, MsgPlusSmsProvider } from './sms/sms.providers';
import { JwtStrategy } from './strategies/jwt.strategy';

@Module({
  imports: [JwtModule.register({}), PassportModule],
  controllers: [AuthController],
  providers: [
    AuthService,
    OtpService,
    JwtStrategy,
    {
      provide: SMS_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService): SmsProvider => {
        if (config.get('NODE_ENV') !== 'production') return new ConsoleSmsProvider();
        switch (config.get('SMS_PROVIDER')) {
          case 'msgplus': return new MsgPlusSmsProvider(config);
          case 'http': return new HttpSmsProvider(config);
          default: throw new Error('SMS_PROVIDER must be explicitly configured in production');
        }
      },
    },
  ],
  exports: [AuthService],
})
export class AuthModule {}
