import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UsersController } from './users.controller';
import { ProfilePhotoStorageService } from './profile-photo-storage.service';
import { UsersService } from './users.service';

@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET') || 'dev-secret',
        signOptions: { expiresIn: '7d' },
      }),
    }),
  ],
  controllers: [UsersController],
  providers: [UsersService, ProfilePhotoStorageService, JwtAuthGuard],
  exports: [UsersService],
})
export class UsersModule {}
