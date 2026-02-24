import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AuthModule } from './auth/auth.module';
import { ChallengesModule } from './challenges/challenges.module';
import { PrismaModule } from './prisma/prisma.module';
import { RankingModule } from './ranking/ranking.module';
import { SubmissionsModule } from './submissions/submissions.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    UsersModule,
    AuthModule,
    ChallengesModule,
    SubmissionsModule,
    RankingModule,
  ],
  controllers: [AppController],
  providers: [],
})
export class AppModule {}
