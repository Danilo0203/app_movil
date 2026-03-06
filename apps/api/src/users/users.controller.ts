import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { extname } from 'path';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ProfilePhotoStorageService } from './profile-photo-storage.service';
import { UsersService } from './users.service';

@Controller(['users', 'user'])
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly profilePhotoStorageService: ProfilePhotoStorageService,
  ) {}

  @Get()
  findAll() {
    return this.usersService.findAllPublic();
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() user: { id: number }) {
    return this.usersService.findPublicById(user.id);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  updateProfile(
    @CurrentUser() user: { id: number },
    @Body() dto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(user.id, dto);
  }

  @Post('me/change-password')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  changePassword(
    @CurrentUser() user: { id: number },
    @Body() dto: ChangePasswordDto,
  ) {
    return this.usersService.changePassword(user.id, dto);
  }

  @Post('me/avatar')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      fileFilter: (_req, file, cb) => {
        const mimeType = (file.mimetype || '').toLowerCase();
        const fileExt = extname(file.originalname || '').toLowerCase();
        const allowedImageExtensions = new Set([
          '.jpg',
          '.jpeg',
          '.png',
          '.webp',
          '.heic',
          '.heif',
        ]);
        const isImageMimeType = mimeType.startsWith('image/');
        const isGenericBinaryImage =
          mimeType === 'application/octet-stream' &&
          allowedImageExtensions.has(fileExt);

        if (!isImageMimeType && !isGenericBinaryImage) {
          return cb(
            new BadRequestException('Only image files are allowed') as any,
            false,
          );
        }
        cb(null, true);
      },
      limits: { fileSize: 8 * 1024 * 1024 },
    }),
  )
  async uploadAvatar(
    @CurrentUser() user: { id: number },
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    const avatarUrl = await this.profilePhotoStorageService.storeUserAvatar({
      file,
      userId: user.id,
    });

    return this.usersService.updateAvatar(user.id, avatarUrl);
  }
}
