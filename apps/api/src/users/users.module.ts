import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { ProfilePhotoStorageService } from './profile-photo-storage.service';
import { UsersService } from './users.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService, ProfilePhotoStorageService],
  exports: [UsersService],
})
export class UsersModule {}
