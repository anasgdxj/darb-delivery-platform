-- Additive non-destructive migration for in-app notifications, driver order dismissals, and review uniqueness
CREATE TABLE IF NOT EXISTS "UserNotification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "body" TEXT NOT NULL,
    "type" VARCHAR(48) NOT NULL DEFAULT 'GENERAL',
    "data" JSONB,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserNotification_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "DriverDismissedOrder" (
    "id" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DriverDismissedOrder_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "UserNotification_userId_createdAt_idx" ON "UserNotification"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "UserNotification_userId_readAt_idx" ON "UserNotification"("userId", "readAt");
CREATE UNIQUE INDEX IF NOT EXISTS "DriverDismissedOrder_driverId_orderId_key" ON "DriverDismissedOrder"("driverId", "orderId");
CREATE INDEX IF NOT EXISTS "DriverDismissedOrder_driverId_orderId_idx" ON "DriverDismissedOrder"("driverId", "orderId");
CREATE UNIQUE INDEX IF NOT EXISTS "Review_orderId_authorId_key" ON "Review"("orderId", "authorId");
CREATE INDEX IF NOT EXISTS "Review_vendorId_createdAt_idx" ON "Review"("vendorId", "createdAt");

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'UserNotification_userId_fkey') THEN
    ALTER TABLE "UserNotification" ADD CONSTRAINT "UserNotification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'DriverDismissedOrder_driverId_fkey') THEN
    ALTER TABLE "DriverDismissedOrder" ADD CONSTRAINT "DriverDismissedOrder_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'DriverDismissedOrder_orderId_fkey') THEN
    ALTER TABLE "DriverDismissedOrder" ADD CONSTRAINT "DriverDismissedOrder_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

ALTER TABLE "public"."UserNotification" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."DriverDismissedOrder" ENABLE ROW LEVEL SECURITY;
