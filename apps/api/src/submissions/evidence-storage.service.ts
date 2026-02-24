import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from '@supabase/supabase-js';
import { mkdir, writeFile } from 'fs/promises';
import { extname, join } from 'path';
import { v4 as uuidv4 } from 'uuid';

type StoreSubmissionPhotoParams = {
  file: Express.Multer.File;
  submissionId: number;
  itemCode: string;
  userId: number;
};

@Injectable()
export class EvidenceStorageService {
  constructor(private readonly configService: ConfigService) {}

  async storeSubmissionPhoto(params: StoreSubmissionPhotoParams): Promise<string> {
    const objectName = this.buildObjectName(params);

    if (this.hasSupabaseConfig()) {
      return this.storeInSupabase(params.file, objectName);
    }

    return this.storeOnDisk(params.file, objectName);
  }

  private hasSupabaseConfig(): boolean {
    return Boolean(
      this.configService.get<string>('SUPABASE_URL') &&
        this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  private buildObjectName(params: StoreSubmissionPhotoParams): string {
    const extension = extname(params.file.originalname || '').toLowerCase() || '.jpg';
    const safeItemCode = params.itemCode.replace(/[^a-zA-Z0-9_-]/g, '_');
    return `submissions/${params.submissionId}/u${params.userId}_${safeItemCode}_${Date.now()}_${uuidv4()}${extension}`;
  }

  private async storeInSupabase(
    file: Express.Multer.File,
    objectName: string,
  ): Promise<string> {
    const url = this.configService.getOrThrow<string>('SUPABASE_URL');
    const serviceRoleKey = this.configService.getOrThrow<string>(
      'SUPABASE_SERVICE_ROLE_KEY',
    );
    const bucket =
      this.configService.get<string>('SUPABASE_STORAGE_BUCKET') ||
      'submission-evidence';

    const client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { error } = await client.storage.from(bucket).upload(objectName, file.buffer, {
      contentType: file.mimetype || 'image/jpeg',
      upsert: false,
    });
    if (error) {
      throw new Error(`Supabase upload failed: ${error.message}`);
    }

    return `supabase://${bucket}/${objectName}`;
  }

  private async storeOnDisk(
    file: Express.Multer.File,
    objectName: string,
  ): Promise<string> {
    const uploadsDir = this.configService.get<string>('UPLOADS_DIR') || './uploads';
    const fileName = objectName.split('/').at(-1) || `${Date.now()}-${uuidv4()}.jpg`;
    const absoluteDir = join(process.cwd(), uploadsDir);
    await mkdir(absoluteDir, { recursive: true });
    await writeFile(join(absoluteDir, fileName), file.buffer);
    return join(uploadsDir, fileName).replace(/\\/g, '/');
  }
}
