import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { compare, hash } from 'bcryptjs';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { JwtPayload } from './types/jwt-payload.type';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: CreateUserDto) {
    const passwordHash = await hash(dto.password, 10);
    const user = await this.usersService.createAuthUser({
      name: dto.name,
      email: dto.email,
      passwordHash,
    });

    return this.issueAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isValid = await compare(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.issueAuthResponse({
      id: user.id,
      name: user.name,
      email: user.email,
      createdAt: user.createdAt,
    });
  }

  me(userId: number) {
    return this.usersService.findPublicById(userId);
  }

  private async issueAuthResponse(user: {
    id: number;
    name: string;
    email: string;
    createdAt: Date;
  }) {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      name: user.name,
    };

    const accessToken = await this.jwtService.signAsync(payload);

    return {
      accessToken,
      user,
    };
  }
}
