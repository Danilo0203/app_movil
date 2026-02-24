import { Type } from 'class-transformer';
import { IsInt, Min } from 'class-validator';

export class CreateSubmissionDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  challengeId!: number;
}
