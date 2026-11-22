ALTER TABLE "Order"
  ADD COLUMN IF NOT EXISTS "pickupLatitude" DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "pickupLongitude" DOUBLE PRECISION;

DO $$ BEGIN
  ALTER TABLE "Order" ADD CONSTRAINT "Order_pickup_coordinates_pair_check"
    CHECK (("pickupLatitude" IS NULL AND "pickupLongitude" IS NULL) OR ("pickupLatitude" IS NOT NULL AND "pickupLongitude" IS NOT NULL));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "Order" ADD CONSTRAINT "Order_pickup_latitude_range_check"
    CHECK ("pickupLatitude" IS NULL OR ("pickupLatitude" >= -90 AND "pickupLatitude" <= 90));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "Order" ADD CONSTRAINT "Order_pickup_longitude_range_check"
    CHECK ("pickupLongitude" IS NULL OR ("pickupLongitude" >= -180 AND "pickupLongitude" <= 180));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
