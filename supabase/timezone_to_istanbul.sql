-- =====================================================================
-- Tüm zaman damgası kolonlarını Türkiye saatine (Europe/Istanbul) çevirir.
-- Çalıştırdıktan sonra Supabase Studio'da kolonlar doğrudan TR saati gösterir.
-- timestamptz -> timestamp (zone'suz) dönüşümü yapılır,
-- mevcut UTC kayıtlar Europe/Istanbul'a çevrilerek korunur,
-- yeni eklenecek kayıtların default'u Europe/Istanbul olur.
-- =====================================================================

BEGIN;

-- profiles
ALTER TABLE profiles
  ALTER COLUMN created_at DROP DEFAULT,
  ALTER COLUMN created_at TYPE timestamp
    USING (created_at AT TIME ZONE 'Europe/Istanbul'),
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'Europe/Istanbul');

-- routes
ALTER TABLE routes
  ALTER COLUMN created_at DROP DEFAULT,
  ALTER COLUMN created_at TYPE timestamp
    USING (created_at AT TIME ZONE 'Europe/Istanbul'),
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'Europe/Istanbul');

-- students
ALTER TABLE students
  ALTER COLUMN created_at DROP DEFAULT,
  ALTER COLUMN created_at TYPE timestamp
    USING (created_at AT TIME ZONE 'Europe/Istanbul'),
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'Europe/Istanbul');

-- trips
ALTER TABLE trips
  ALTER COLUMN started_at DROP DEFAULT,
  ALTER COLUMN started_at TYPE timestamp
    USING (started_at AT TIME ZONE 'Europe/Istanbul'),
  ALTER COLUMN started_at SET DEFAULT (now() AT TIME ZONE 'Europe/Istanbul');

ALTER TABLE trips
  ALTER COLUMN ended_at TYPE timestamp
    USING (ended_at AT TIME ZONE 'Europe/Istanbul');

-- attendance
ALTER TABLE attendance
  ALTER COLUMN timestamp DROP DEFAULT,
  ALTER COLUMN timestamp TYPE timestamp
    USING (timestamp AT TIME ZONE 'Europe/Istanbul'),
  ALTER COLUMN timestamp SET DEFAULT (now() AT TIME ZONE 'Europe/Istanbul');

-- logs
ALTER TABLE logs
  ALTER COLUMN created_at DROP DEFAULT,
  ALTER COLUMN created_at TYPE timestamp
    USING (created_at AT TIME ZONE 'Europe/Istanbul'),
  ALTER COLUMN created_at SET DEFAULT (now() AT TIME ZONE 'Europe/Istanbul');

COMMIT;
