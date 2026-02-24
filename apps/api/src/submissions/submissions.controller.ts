import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseIntPipe,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { v4 as uuidv4 } from 'uuid';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateSubmissionDto } from './dto/create-submission.dto';
import { UploadSubmissionPhotoDto } from './dto/upload-submission-photo.dto';
import { SubmissionsService } from './submissions.service';

@Controller('submissions')
@UseGuards(JwtAuthGuard)
export class SubmissionsController {
  constructor(
    private readonly submissionsService: SubmissionsService,
    private readonly configService: ConfigService,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(
    @CurrentUser() user: { id: number },
    @Body() dto: CreateSubmissionDto,
  ) {
    return this.submissionsService.create(user.id, dto.challengeId);
  }

  @Get('my')
  my(@CurrentUser() user: { id: number }) {
    return this.submissionsService.mySubmissions(user.id);
  }

  @Get(':id')
  findOne(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: { id: number },
  ) {
    return this.submissionsService.findOneForUser(id, user.id);
  }

  @Post(':id/photos')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          const uploadsDir = process.env.UPLOADS_DIR || './uploads';
          const absolute = join(process.cwd(), uploadsDir);
          if (!existsSync(absolute)) {
            mkdirSync(absolute, { recursive: true });
          }
          cb(null, absolute);
        },
        filename: (_req, file, cb) => {
          const extension = extname(file.originalname || '').toLowerCase() || '.jpg';
          cb(null, `${Date.now()}-${uuidv4()}${extension}`);
        },
      }),
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.startsWith('image/')) {
          return cb(new BadRequestException('Only image files are allowed') as any, false);
        }
        cb(null, true);
      },
      limits: { fileSize: 8 * 1024 * 1024 },
    }),
  )
  async uploadPhoto(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: { id: number },
    @Body() dto: UploadSubmissionPhotoDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    const uploadsDir = this.configService.get<string>('UPLOADS_DIR') || './uploads';
    const relativePath = join(uploadsDir, file.filename).replace(/\\/g, '/');

    return this.submissionsService.addEvidence({
      submissionId: id,
      userId: user.id,
      itemCode: dto.itemCode,
      photoPath: relativePath,
    });
  }

  @Post(':id/complete')
  complete(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: { id: number },
  ) {
    return this.submissionsService.complete(id, user.id);
  }
}
