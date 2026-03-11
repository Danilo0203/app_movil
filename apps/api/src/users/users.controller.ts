import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
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
import { IdempotencyService } from '../idempotency/idempotency.service';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ProfilePhotoStorageService } from './profile-photo-storage.service';
import { UsersService } from './users.service';

@Controller(['users', 'user'])
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly profilePhotoStorageService: ProfilePhotoStorageService,
    private readonly idempotencyService: IdempotencyService,
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
    @Headers('x-client-request-id') clientRequestId?: string,
  ) {
    return this.withIdempotency({
      clientRequestId,
      operation: 'users.updateProfile',
      userId: user.id,
      resolve: () => this.usersService.updateProfile(user.id, dto),
    });
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
    @Headers('x-client-request-id') clientRequestId?: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    return this.withIdempotency({
      clientRequestId,
      operation: 'users.uploadAvatar',
      userId: user.id,
      resolve: async () => {
        const avatarUrl = await this.profilePhotoStorageService.storeUserAvatar(
          {
            file,
            userId: user.id,
            clientRequestId,
          },
        );

        return this.usersService.updateAvatar(user.id, avatarUrl);
      },
    });
  }

  private async withIdempotency<T>(params: {
    clientRequestId?: string;
    operation: string;
    userId: number;
    resolve: () => Promise<T>;
  }): Promise<T> {
    const existing = await this.idempotencyService.findResponse<T>({
      clientRequestId: params.clientRequestId,
      userId: params.userId,
      operation: params.operation,
    });
    if (existing != null) {
      return existing;
    }

    const response = await params.resolve();
    await this.idempotencyService.saveResponse({
      clientRequestId: params.clientRequestId,
      userId: params.userId,
      operation: params.operation,
      response,
    });
    return response;
  }
}
