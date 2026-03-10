import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from '@supabase/supabase-js';
import { mkdir, writeFile } from 'fs/promises';
import { extname, join } from 'path';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class ProfilePhotoStorageService {
  constructor(private readonly configService: ConfigService) {}

  async storeUserAvatar(params: {
    file: Express.Multer.File;
    userId: number;
  }): Promise<string> {
    const objectName = this.buildObjectName(params.file, params.userId);

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

  private buildObjectName(file: Express.Multer.File, userId: number): string {
    const extension = extname(file.originalname || '').toLowerCase() || '.jpg';
    return `avatars/u${userId}_${Date.now()}_${uuidv4()}${extension}`;
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
      this.configService.get<string>('SUPABASE_PROFILE_BUCKET') ||
      'profile-photos';

    const client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { error } = await client.storage
      .from(bucket)
      .upload(objectName, file.buffer, {
        contentType: file.mimetype || 'image/jpeg',
        upsert: false,
      });
    if (error) {
      throw new Error(
        `Supabase upload failed for bucket "${bucket}": ${error.message}`,
      );
    }

    const { data } = client.storage.from(bucket).getPublicUrl(objectName);
    if (!data.publicUrl) {
      throw new Error(
        `Supabase public URL failed for bucket "${bucket}". Verify that the bucket exists and is public.`,
      );
    }
    return data.publicUrl;
  }

  private async storeOnDisk(
    file: Express.Multer.File,
    objectName: string,
  ): Promise<string> {
    const uploadsDir =
      this.configService.get<string>('UPLOADS_DIR') || './uploads';
    const fileName =
      objectName.split('/').at(-1) || `${Date.now()}-${uuidv4()}.jpg`;
    const absoluteDir = join(process.cwd(), uploadsDir, 'avatars');
    await mkdir(absoluteDir, { recursive: true });
    await writeFile(join(absoluteDir, fileName), file.buffer);
    const publicPrefix =
      uploadsDir.replace(/\\/g, '/').split('/').pop() || 'uploads';
    return `/${publicPrefix}/avatars/${fileName}`;
  }
}
