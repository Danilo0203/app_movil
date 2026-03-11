import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class IdempotencyService {
  constructor(private readonly prisma: PrismaService) {}

  async findResponse<T>(params: {
    clientRequestId?: string;
    userId: number;
    operation: string;
  }): Promise<T | null> {
    const key = params.clientRequestId?.trim();
    if (!key) return null;

    const record = await this.prisma.idempotencyRequest.findUnique({
      where: { clientRequestId: key },
    });
    if (!record) return null;
    if (
      record.userId !== params.userId ||
      record.operation !== params.operation
    ) {
      return null;
    }
    return record.responseJson as T;
  }

  async saveResponse(params: {
    clientRequestId?: string;
    userId: number;
    operation: string;
    response: unknown;
  }): Promise<void> {
    const key = params.clientRequestId?.trim();
    if (!key) return;
    const serialized = JSON.parse(
      JSON.stringify(params.response),
    ) as Prisma.InputJsonValue;

    await this.prisma.idempotencyRequest.upsert({
      where: { clientRequestId: key },
      create: {
        clientRequestId: key,
        userId: params.userId,
        operation: params.operation,
        responseJson: serialized,
      },
      update: {
        responseJson: serialized,
        operation: params.operation,
        userId: params.userId,
      },
    });
  }
}
