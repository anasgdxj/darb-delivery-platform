CREATE TYPE "AiDraftSource" AS ENUM ('TEXT', 'AUDIO');
CREATE TYPE "AiDraftStatus" AS ENUM ('PROCESSING', 'READY', 'NEEDS_REVIEW', 'FAILED');
CREATE TYPE "AiDraftIntent" AS ENUM ('STORE_ORDER', 'PEER_DELIVERY', 'UNCLEAR');

CREATE TABLE "AiOrderDraft" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "cityId" TEXT NOT NULL,
  "vendorId" TEXT,
  "idempotencyKey" VARCHAR(80),
  "source" "AiDraftSource" NOT NULL,
  "status" "AiDraftStatus" NOT NULL DEFAULT 'PROCESSING',
  "intent" "AiDraftIntent" NOT NULL DEFAULT 'UNCLEAR',
  "originalText" TEXT,
  "transcript" TEXT,
  "locale" "Locale" NOT NULL DEFAULT 'ar',
  "confidence" DOUBLE PRECISION,
  "warnings" JSONB,
  "extraction" JSONB,
  "errorCode" VARCHAR(60),
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "AiOrderDraft_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "AiOrderDraftItem" (
  "id" TEXT NOT NULL,
  "draftId" TEXT NOT NULL,
  "productId" TEXT,
  "rawName" VARCHAR(240) NOT NULL,
  "normalizedName" VARCHAR(240),
  "quantity" INTEGER NOT NULL DEFAULT 1,
  "unit" VARCHAR(40),
  "confidence" DOUBLE PRECISION,
  "candidates" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AiOrderDraftItem_pkey" PRIMARY KEY ("id")
);
CREATE TABLE "AiAddressDraft" (
  "id" TEXT NOT NULL,
  "draftId" TEXT NOT NULL,
  "rawText" TEXT,
  "normalizedText" TEXT,
  "neighborhood" VARCHAR(160),
  "street" VARCHAR(200),
  "building" VARCHAR(160),
  "landmark" VARCHAR(240),
  "recipientName" VARCHAR(120),
  "recipientPhone" VARCHAR(40),
  "deliveryNotes" TEXT,
  "latitude" DOUBLE PRECISION,
  "longitude" DOUBLE PRECISION,
  "geocodeStatus" VARCHAR(24) NOT NULL DEFAULT 'PENDING',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "AiAddressDraft_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "AiOrderDraft_userId_idempotencyKey_key" ON "AiOrderDraft"("userId", "idempotencyKey");
CREATE INDEX "AiOrderDraft_userId_status_createdAt_idx" ON "AiOrderDraft"("userId", "status", "createdAt");
CREATE INDEX "AiOrderDraft_expiresAt_idx" ON "AiOrderDraft"("expiresAt");
CREATE INDEX "AiOrderDraftItem_draftId_idx" ON "AiOrderDraftItem"("draftId");
CREATE INDEX "AiOrderDraftItem_productId_idx" ON "AiOrderDraftItem"("productId");
CREATE UNIQUE INDEX "AiAddressDraft_draftId_key" ON "AiAddressDraft"("draftId");
ALTER TABLE "AiOrderDraft" ADD CONSTRAINT "AiOrderDraft_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "AiOrderDraftItem" ADD CONSTRAINT "AiOrderDraftItem_draftId_fkey" FOREIGN KEY ("draftId") REFERENCES "AiOrderDraft"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "AiOrderDraftItem" ADD CONSTRAINT "AiOrderDraftItem_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "AiAddressDraft" ADD CONSTRAINT "AiAddressDraft_draftId_fkey" FOREIGN KEY ("draftId") REFERENCES "AiOrderDraft"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "locale" "Locale" NOT NULL DEFAULT 'ar';
