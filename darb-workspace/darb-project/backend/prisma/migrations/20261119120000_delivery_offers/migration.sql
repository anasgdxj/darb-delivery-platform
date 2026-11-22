CREATE TYPE "OfferStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'WITHDRAWN');

CREATE TABLE "DeliveryOffer" (
  "id" TEXT NOT NULL,
  "orderId" TEXT NOT NULL,
  "driverId" TEXT NOT NULL,
  "amount" DECIMAL(12,2) NOT NULL,
  "currency" VARCHAR(3) NOT NULL,
  "status" "OfferStatus" NOT NULL DEFAULT 'PENDING',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "DeliveryOffer_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "DeliveryOffer_orderId_driverId_key" ON "DeliveryOffer"("orderId", "driverId");
CREATE INDEX "DeliveryOffer_orderId_status_amount_idx" ON "DeliveryOffer"("orderId", "status", "amount");
CREATE INDEX "DeliveryOffer_driverId_status_createdAt_idx" ON "DeliveryOffer"("driverId", "status", "createdAt");

ALTER TABLE "DeliveryOffer" ADD CONSTRAINT "DeliveryOffer_orderId_fkey"
  FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "DeliveryOffer" ADD CONSTRAINT "DeliveryOffer_driverId_fkey"
  FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE CASCADE ON UPDATE CASCADE;
