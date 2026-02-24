import { Injectable } from '@nestjs/common';
import { SubmissionStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RankingService {
  constructor(private readonly prisma: PrismaService) {}

  async global() {
    const submissions = await this.prisma.submission.findMany({
      where: { status: SubmissionStatus.COMPLETED },
      include: { user: true, evidences: true },
    });

    const map = new Map<
      number,
      {
        userId: number;
        name: string;
        email: string;
        completedChallenges: number;
        evidences: number;
        points: number;
        lastCompletedAt: Date | null;
      }
    >();

    for (const submission of submissions) {
      const existing = map.get(submission.userId) ?? {
        userId: submission.userId,
        name: submission.user.name,
        email: submission.user.email,
        completedChallenges: 0,
        evidences: 0,
        points: 0,
        lastCompletedAt: null,
      };

      existing.completedChallenges += 1;
      existing.evidences += submission.evidences.length;
      existing.points += 10 + submission.evidences.length * 2;

      if (
        submission.completedAt &&
        (!existing.lastCompletedAt || submission.completedAt > existing.lastCompletedAt)
      ) {
        existing.lastCompletedAt = submission.completedAt;
      }

      map.set(submission.userId, existing);
    }

    return [...map.values()].sort((a, b) => {
      if (b.points !== a.points) return b.points - a.points;
      if (!a.lastCompletedAt && !b.lastCompletedAt) return 0;
      if (!a.lastCompletedAt) return 1;
      if (!b.lastCompletedAt) return -1;
      return b.lastCompletedAt.getTime() - a.lastCompletedAt.getTime();
    });
  }
}
