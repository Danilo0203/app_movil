import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { defaultChallenges } from './default-challenges';

@Injectable()
export class ChallengesService {
  constructor(private readonly prisma: PrismaService) {}

  list() {
    return this.prisma.challenge.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  findById(id: number) {
    return this.prisma.challenge.findUnique({ where: { id } });
  }

  async seedDefaults() {
    const created: Array<{
      id: number;
      title: string;
      type: string;
      itemsJson: unknown;
      createdAt: Date;
    }> = [];
    for (const challenge of defaultChallenges) {
      const record = await this.prisma.challenge.upsert({
        where: { type: challenge.type },
        update: {
          title: challenge.title,
          itemsJson: challenge.itemsJson as any,
        },
        create: {
          title: challenge.title,
          type: challenge.type,
          itemsJson: challenge.itemsJson as any,
        },
      });
      created.push(record);
    }
    return { count: created.length, challenges: created };
  }
}
