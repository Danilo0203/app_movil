import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { resolve } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const uploadsDir = process.env.UPLOADS_DIR || './uploads';
  const uploadsPrefix = `/${uploadsDir.replace(/\\/g, '/').split('/').pop() || 'uploads'}`;

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useStaticAssets(resolve(process.cwd(), uploadsDir), {
    prefix: `${uploadsPrefix}/`,
  });
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
