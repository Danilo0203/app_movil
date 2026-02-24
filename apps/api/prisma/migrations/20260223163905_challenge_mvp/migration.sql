-- Extend User for auth
ALTER TABLE "User"
ADD COLUMN IF NOT EXISTS "name" TEXT NOT NULL DEFAULT 'Usuario',
ADD COLUMN IF NOT EXISTS "passwordHash" TEXT NOT NULL DEFAULT '';

-- Enums
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ChallengeType') THEN
    CREATE TYPE "ChallengeType" AS ENUM ('MYSTERY', 'OFFICE_SAFARI', 'TECHNICAL_INSPECTOR');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SubmissionStatus') THEN
    CREATE TYPE "SubmissionStatus" AS ENUM ('IN_PROGRESS', 'COMPLETED');
  END IF;
END $$;

-- Challenges catalog
CREATE TABLE IF NOT EXISTS "Challenge" (
  "id" SERIAL NOT NULL,
  "title" TEXT NOT NULL,
  "type" "ChallengeType" NOT NULL,
  "itemsJson" JSONB NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Challenge_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "Challenge_type_key" ON "Challenge"("type");

-- Submissions (challenge sessions)
CREATE TABLE IF NOT EXISTS "Submission" (
  "id" SERIAL NOT NULL,
  "userId" INTEGER NOT NULL,
  "challengeId" INTEGER NOT NULL,
  "status" "SubmissionStatus" NOT NULL DEFAULT 'IN_PROGRESS',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "completedAt" TIMESTAMP(3),
  CONSTRAINT "Submission_pkey" PRIMARY KEY ("id")
);

-- Evidence rows (one per checklist item)
CREATE TABLE IF NOT EXISTS "SubmissionEvidence" (
  "id" SERIAL NOT NULL,
  "submissionId" INTEGER NOT NULL,
  "itemCode" TEXT NOT NULL,
  "photoPath" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SubmissionEvidence_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "SubmissionEvidence_submissionId_itemCode_key"
ON "SubmissionEvidence"("submissionId", "itemCode");

-- FKs
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Submission_userId_fkey'
  ) THEN
    ALTER TABLE "Submission"
      ADD CONSTRAINT "Submission_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "User"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Submission_challengeId_fkey'
  ) THEN
    ALTER TABLE "Submission"
      ADD CONSTRAINT "Submission_challengeId_fkey"
      FOREIGN KEY ("challengeId") REFERENCES "Challenge"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'SubmissionEvidence_submissionId_fkey'
  ) THEN
    ALTER TABLE "SubmissionEvidence"
      ADD CONSTRAINT "SubmissionEvidence_submissionId_fkey"
      FOREIGN KEY ("submissionId") REFERENCES "Submission"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;
