-- CreateTable
CREATE TABLE "IdempotencyRequest" (
    "id" SERIAL NOT NULL,
    "clientRequestId" TEXT NOT NULL,
    "userId" INTEGER NOT NULL,
    "operation" TEXT NOT NULL,
    "responseJson" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "IdempotencyRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "IdempotencyRequest_clientRequestId_key" ON "IdempotencyRequest"("clientRequestId");

-- CreateIndex
CREATE INDEX "IdempotencyRequest_userId_operation_idx" ON "IdempotencyRequest"("userId", "operation");

-- AddForeignKey
ALTER TABLE "IdempotencyRequest" ADD CONSTRAINT "IdempotencyRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
