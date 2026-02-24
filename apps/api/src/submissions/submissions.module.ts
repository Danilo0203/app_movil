import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { EvidenceStorageService } from './evidence-storage.service';
import { SubmissionsController } from './submissions.controller';
import { SubmissionsService } from './submissions.service';

@Module({
  imports: [AuthModule],
  controllers: [SubmissionsController],
  providers: [SubmissionsService, EvidenceStorageService],
})
export class SubmissionsModule {}
