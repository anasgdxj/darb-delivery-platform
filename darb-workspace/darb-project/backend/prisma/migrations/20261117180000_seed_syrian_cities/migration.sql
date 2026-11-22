WITH city_data(code, ar_name, en_name, tr_name) AS (
  VALUES
    ('DAMASCUS', 'دمشق', 'Damascus', 'Şam'),
    ('ALEPPO', 'حلب', 'Aleppo', 'Halep'),
    ('HOMS', 'حمص', 'Homs', 'Humus'),
    ('HAMA', 'حماة', 'Hama', 'Hama'),
    ('LATAKIA', 'اللاذقية', 'Latakia', 'Lazkiye'),
    ('TARTUS', 'طرطوس', 'Tartus', 'Tartus'),
    ('IDLIB', 'إدلب', 'Idlib', 'İdlib'),
    ('DARAA', 'درعا', 'Daraa', 'Dera'),
    ('SUWAYDA', 'السويداء', 'As-Suwayda', 'Süveyda'),
    ('RAQQA', 'الرقة', 'Raqqa', 'Rakka'),
    ('DEIR_EZZOR', 'دير الزور', 'Deir ez-Zor', 'Deyrizor'),
    ('QAMISHLI', 'القامشلي', 'Qamishli', 'Kamışlı')
)
INSERT INTO "City" ("id", "code", "defaultCurrency", "supportedLocales", "isActive", "createdAt")
SELECT substr(md5('darb-city:' || code),1,8) || '-' || substr(md5('darb-city:' || code),9,4) || '-' || substr(md5('darb-city:' || code),13,4) || '-' || substr(md5('darb-city:' || code),17,4) || '-' || substr(md5('darb-city:' || code),21,12), code, 'SYP',
       ARRAY['ar'::"Locale", 'en'::"Locale", 'tr'::"Locale"], TRUE, NOW()
FROM city_data
ON CONFLICT ("code") DO UPDATE
SET "isActive" = TRUE, "supportedLocales" = EXCLUDED."supportedLocales";

WITH city_data(code, ar_name, en_name, tr_name) AS (
  VALUES
    ('DAMASCUS', 'دمشق', 'Damascus', 'Şam'),
    ('ALEPPO', 'حلب', 'Aleppo', 'Halep'),
    ('HOMS', 'حمص', 'Homs', 'Humus'),
    ('HAMA', 'حماة', 'Hama', 'Hama'),
    ('LATAKIA', 'اللاذقية', 'Latakia', 'Lazkiye'),
    ('TARTUS', 'طرطوس', 'Tartus', 'Tartus'),
    ('IDLIB', 'إدلب', 'Idlib', 'İdlib'),
    ('DARAA', 'درعا', 'Daraa', 'Dera'),
    ('SUWAYDA', 'السويداء', 'As-Suwayda', 'Süveyda'),
    ('RAQQA', 'الرقة', 'Raqqa', 'Rakka'),
    ('DEIR_EZZOR', 'دير الزور', 'Deir ez-Zor', 'Deyrizor'),
    ('QAMISHLI', 'القامشلي', 'Qamishli', 'Kamışlı')
),
translations AS (
  SELECT c.id AS "cityId", c.code, 'ar'::"Locale" AS locale, d.ar_name AS name FROM "City" c JOIN city_data d USING (code)
  UNION ALL
  SELECT c.id, c.code, 'en'::"Locale", d.en_name FROM "City" c JOIN city_data d USING (code)
  UNION ALL
  SELECT c.id, c.code, 'tr'::"Locale", d.tr_name FROM "City" c JOIN city_data d USING (code)
)
INSERT INTO "CityTranslation" ("id", "cityId", "locale", "name")
SELECT substr(md5('darb-city-translation:' || code || ':' || locale::text),1,8) || '-' || substr(md5('darb-city-translation:' || code || ':' || locale::text),9,4) || '-' || substr(md5('darb-city-translation:' || code || ':' || locale::text),13,4) || '-' || substr(md5('darb-city-translation:' || code || ':' || locale::text),17,4) || '-' || substr(md5('darb-city-translation:' || code || ':' || locale::text),21,12), "cityId", locale, name
FROM translations
ON CONFLICT ("cityId", "locale") DO UPDATE SET "name" = EXCLUDED."name";
