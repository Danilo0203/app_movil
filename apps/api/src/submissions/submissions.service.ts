import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, SubmissionStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SubmissionsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: number, challengeId: number) {
    const challenge = await this.prisma.challenge.findUnique({
      where: { id: challengeId },
    });
    if (!challenge) {
      throw new NotFoundException('Challenge not found');
    }

    const existing = await this.prisma.submission.findFirst({
      where: { userId, challengeId, status: SubmissionStatus.IN_PROGRESS },
      include: { challenge: true, evidences: true },
      orderBy: { createdAt: 'desc' },
    });
    if (existing) {
      return existing;
    }

    return this.prisma.submission.create({
      data: { userId, challengeId },
      include: { challenge: true, evidences: true },
    });
  }

  mySubmissions(userId: number) {
    return this.prisma.submission.findMany({
      where: { userId },
      include: { challenge: true, evidences: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOneForUser(id: number, userId: number) {
    const submission = await this.prisma.submission.findFirst({
      where: { id, userId },
      include: { challenge: true, evidences: true },
    });
    if (!submission) {
      throw new NotFoundException('Submission not found');
    }
    return submission;
  }

  async addEvidence(params: {
    submissionId: number;
    userId: number;
    itemCode: string;
    photoPath: string;
  }) {
    const submission = await this.prisma.submission.findFirst({
      where: { id: params.submissionId, userId: params.userId },
      include: { challenge: true, evidences: true },
    });
    if (!submission) {
      throw new NotFoundException('Submission not found');
    }
    if (submission.status === SubmissionStatus.COMPLETED) {
      throw new BadRequestException('Submission is already completed');
    }

    const items = Array.isArray(submission.challenge.itemsJson)
      ? (submission.challenge.itemsJson as unknown as Array<{ code?: string }>)
      : [];
    const validCodes = new Set(
      items.map((item) => item.code).filter(Boolean) as string[],
    );
    if (!validCodes.has(params.itemCode)) {
      throw new BadRequestException('Invalid itemCode for this challenge');
    }

    try {
      return await this.prisma.submissionEvidence.create({
        data: {
          submissionId: params.submissionId,
          itemCode: params.itemCode,
          photoPath: params.photoPath,
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'Evidence for this itemCode already exists',
        );
      }
      throw error;
    }
  }

  async complete(submissionId: number, userId: number) {
    const submission = await this.prisma.submission.findFirst({
      where: { id: submissionId, userId },
      include: { challenge: true, evidences: true },
    });
    if (!submission) {
      throw new NotFoundException('Submission not found');
    }
    if (submission.status === SubmissionStatus.COMPLETED) {
      return submission;
    }

    const items = Array.isArray(submission.challenge.itemsJson)
      ? (submission.challenge.itemsJson as unknown as Array<{ code?: string }>)
      : [];
    const requiredCodes = [
      ...new Set(items.map((item) => item.code).filter(Boolean) as string[]),
    ];
    const submittedCodes = new Set(submission.evidences.map((e) => e.itemCode));
    const missing = requiredCodes.filter((code) => !submittedCodes.has(code));
    if (missing.length > 0) {
      throw new BadRequestException({
        message: 'Checklist is incomplete',
        missing,
      });
    }

    return this.prisma.submission.update({
      where: { id: submissionId },
      data: {
        status: SubmissionStatus.COMPLETED,
        completedAt: new Date(),
      },
      include: { challenge: true, evidences: true },
    });
  }
}
