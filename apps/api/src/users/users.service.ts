import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { compare, hash } from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly publicUserSelect = {
    id: true,
    name: true,
    email: true,
    phone: true,
    address: true,
    avatarUrl: true,
    createdAt: true,
    updatedAt: true,
  } as const;

  findAllPublic() {
    return this.prisma.user.findMany({
      select: this.publicUserSelect,
      orderBy: { createdAt: 'desc' },
    });
  }

  findByEmail(email: string) {
    return this.prisma.user.findUnique({ where: { email } });
  }

  findPublicById(id: number) {
    return this.prisma.user.findUnique({
      where: { id },
      select: this.publicUserSelect,
    });
  }

  async createAuthUser(params: {
    name: string;
    email: string;
    passwordHash: string;
  }) {
    try {
      return await this.prisma.user.create({
        data: params,
        select: this.publicUserSelect,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('Email already exists');
      }
      throw error;
    }
  }

  async updateProfile(userId: number, dto: UpdateProfileDto) {
    const data: Prisma.UserUpdateInput = {};

    if (dto.name !== undefined) data.name = dto.name;
    if (dto.email !== undefined) data.email = dto.email;
    if (dto.phone !== undefined) data.phone = dto.phone || null;
    if (dto.address !== undefined) data.address = dto.address || null;

    if (Object.keys(data).length === 0) {
      throw new BadRequestException('No profile fields provided');
    }

    try {
      return await this.prisma.user.update({
        where: { id: userId },
        data,
        select: this.publicUserSelect,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('Email already exists');
      }
      throw error;
    }
  }

  async changePassword(userId: number, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, passwordHash: true },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isCurrentPasswordValid = await compare(
      dto.currentPassword,
      user.passwordHash,
    );
    if (!isCurrentPasswordValid) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    const isSamePassword = await compare(dto.newPassword, user.passwordHash);
    if (isSamePassword) {
      throw new BadRequestException(
        'New password must be different from current password',
      );
    }

    const newPasswordHash = await hash(dto.newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: newPasswordHash },
    });

    return { success: true };
  }

  async updateAvatar(userId: number, avatarUrl: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl },
      select: this.publicUserSelect,
    });
  }
}
