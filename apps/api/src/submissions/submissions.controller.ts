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
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateSubmissionDto } from './dto/create-submission.dto';
import { EvidenceStorageService } from './evidence-storage.service';
import { UploadSubmissionPhotoDto } from './dto/upload-submission-photo.dto';
import { SubmissionsService } from './submissions.service';

@Controller('submissions')
@UseGuards(JwtAuthGuard)
export class SubmissionsController {
  constructor(
    private readonly submissionsService: SubmissionsService,
    private readonly evidenceStorageService: EvidenceStorageService,
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
      storage: memoryStorage(),
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

    const photoPath = await this.evidenceStorageService.storeSubmissionPhoto({
      file,
      submissionId: id,
      itemCode: dto.itemCode,
      userId: user.id,
    });

    return this.submissionsService.addEvidence({
      submissionId: id,
      userId: user.id,
      itemCode: dto.itemCode,
      photoPath,
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
