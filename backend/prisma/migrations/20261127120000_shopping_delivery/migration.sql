ALTER TYPE "OrderType" ADD VALUE IF NOT EXISTS 'SHOPPING_DELIVERY';
CREATE TYPE "ShoppingQuoteStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'SUPERSEDED');

ALTER TABLE "Order"
  ADD COLUMN "shoppingItemName" VARCHAR(180),
  ADD COLUMN "shoppingDescription" TEXT,
  ADD COLUMN "shoppingStoreName" VARCHAR(180),
  ADD COLUMN "shoppingStoreAddress" TEXT,
  ADD COLUMN "shoppingMaxBudget" DECIMAL(12,2);

CREATE TABLE "ShoppingPurchaseQuote" (
  "id" TEXT NOT NULL,
  "orderId" TEXT NOT NULL,
  "driverId" TEXT NOT NULL,
  "amount" DECIMAL(12,2) NOT NULL,
  "currency" VARCHAR(3) NOT NULL,
  "details" TEXT NOT NULL,
  "status" "ShoppingQuoteStatus" NOT NULL DEFAULT 'PENDING',
  "approvedAt" TIMESTAMP(3),
  "approvedByUserId" TEXT,
  "rejectedAt" TIMESTAMP(3),
  "receiptReference" VARCHAR(180),
  "proofUrl" TEXT,
  "proofNote" TEXT,
  "purchasedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "ShoppingPurchaseQuote_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "ShoppingPurchaseQuote_orderId_status_createdAt_idx"
  ON "ShoppingPurchaseQuote"("orderId", "status", "createdAt");
CREATE INDEX "ShoppingPurchaseQuote_driverId_status_createdAt_idx"
  ON "ShoppingPurchaseQuote"("driverId", "status", "createdAt");

ALTER TABLE "ShoppingPurchaseQuote"
  ADD CONSTRAINT "ShoppingPurchaseQuote_orderId_fkey"
  FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ShoppingPurchaseQuote"
  ADD CONSTRAINT "ShoppingPurchaseQuote_driverId_fkey"
  FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE CASCADE ON UPDATE CASCADE;
