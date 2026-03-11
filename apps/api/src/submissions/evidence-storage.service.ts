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
  clientRequestId?: string;
};

@Injectable()
export class EvidenceStorageService {
  constructor(private readonly configService: ConfigService) {}

  async storeSubmissionPhoto(
    params: StoreSubmissionPhotoParams,
  ): Promise<string> {
    const objectName = this.buildObjectName(params);

    if (this.hasSupabaseConfig()) {
      return this.storeInSupabase(params.file, objectName);
    }

    return this.storeOnDisk(params.file, objectName);
  }

  resolvePhotoPath(photoPath: string): string {
    if (!photoPath) return photoPath;
    if (photoPath.startsWith('supabase://')) {
      return this.resolveSupabasePublicUrl(photoPath);
    }
    if (/^https?:\/\//i.test(photoPath)) {
      return photoPath;
    }

    const normalized = photoPath.replace(/\\/g, '/');
    return normalized.startsWith('/') ? normalized : `/${normalized}`;
  }

  private hasSupabaseConfig(): boolean {
    return Boolean(
      this.configService.get<string>('SUPABASE_URL') &&
      this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  private buildObjectName(params: StoreSubmissionPhotoParams): string {
    const extension =
      extname(params.file.originalname || '').toLowerCase() || '.jpg';
    const safeItemCode = params.itemCode.replace(/[^a-zA-Z0-9_-]/g, '_');
    const normalizedRequestId = params.clientRequestId?.trim();
    const stableSuffix =
      normalizedRequestId && normalizedRequestId.length > 0
        ? normalizedRequestId.replace(/[^a-zA-Z0-9_-]/g, '_')
        : `${Date.now()}_${uuidv4()}`;
    return `submissions/${params.submissionId}/u${params.userId}_${safeItemCode}_${stableSuffix}${extension}`;
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

    const { error } = await client.storage
      .from(bucket)
      .upload(objectName, file.buffer, {
        contentType: file.mimetype || 'image/jpeg',
        upsert: true,
      });
    if (error) {
      throw new Error(`Supabase upload failed: ${error.message}`);
    }

    return `supabase://${bucket}/${objectName}`;
  }

  private resolveSupabasePublicUrl(photoPath: string): string {
    const match = /^supabase:\/\/([^/]+)\/(.+)$/.exec(photoPath);
    if (!match) {
      return photoPath;
    }

    const [, bucket, objectName] = match;
    const url = this.configService.get<string>('SUPABASE_URL');
    const serviceRoleKey = this.configService.get<string>(
      'SUPABASE_SERVICE_ROLE_KEY',
    );

    if (!url || !serviceRoleKey) {
      return photoPath;
    }

    const client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data } = client.storage.from(bucket).getPublicUrl(objectName);
    return data.publicUrl || photoPath;
  }

  private async storeOnDisk(
    file: Express.Multer.File,
    objectName: string,
  ): Promise<string> {
    const uploadsDir =
      this.configService.get<string>('UPLOADS_DIR') || './uploads';
    const fileName =
      objectName.split('/').at(-1) || `${Date.now()}-${uuidv4()}.jpg`;
    const absoluteDir = join(process.cwd(), uploadsDir);
    await mkdir(absoluteDir, { recursive: true });
    await writeFile(join(absoluteDir, fileName), file.buffer);
    return join(uploadsDir, fileName).replace(/\\/g, '/');
  }
}
