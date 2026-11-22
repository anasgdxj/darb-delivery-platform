-- فهارس مكانية (GiST) للاستعلامات الجغرافية
CREATE INDEX IF NOT EXISTS city_boundary_gist      ON "City"           USING GIST (boundary);
CREATE INDEX IF NOT EXISTS vendor_location_gist    ON "VendorLocation" USING GIST (point);
CREATE INDEX IF NOT EXISTS address_point_gist      ON "Address"        USING GIST (point);
CREATE INDEX IF NOT EXISTS driver_location_gist    ON "DriverLocation" USING GIST (point);

-- قيد على مستوى قاعدة البيانات: أرقام سورية محمولة فقط (E.164)
ALTER TABLE "User"
  ADD CONSTRAINT user_phone_syria_chk CHECK (phone ~ '^\+9639[0-9]{8}$');

