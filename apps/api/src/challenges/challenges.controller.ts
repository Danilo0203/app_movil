import {
  Controller,
  Get,
  NotFoundException,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import { ChallengesService } from './challenges.service';

@Controller('challenges')
export class ChallengesController {
  constructor(private readonly challengesService: ChallengesService) {}

  @Get()
  list() {
    return this.challengesService.list();
  }

  @Get(':id')
  async findOne(@Param('id', ParseIntPipe) id: number) {
    const challenge = await this.challengesService.findById(id);
    if (!challenge) {
      throw new NotFoundException('Challenge not found');
    }
    return challenge;
  }

  @Post('seed-defaults')
  seedDefaults() {
    return this.challengesService.seedDefaults();
  }
}
