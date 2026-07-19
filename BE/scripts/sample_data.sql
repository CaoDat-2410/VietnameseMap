-- ================================================================
-- VN Map Campaign - Focused Sample Data
-- Run AFTER seeding base data (users, schools, admin units)
-- All inserts use WHERE NOT EXISTS / ON CONFLICT DO NOTHING
-- so re-running this script is safe.
-- ================================================================

-- ================================================================
-- 1. EMPLOYEES - specific named employees (idempotent)
-- ================================================================
INSERT INTO employees (id, full_name, role) VALUES
  (1,  'Nguyen Van An',     'STAFF'),
  (2,  'Tran Thi Binh',     'STAFF'),
  (3,  'Le Hoang Cuong',    'STAFF'),
  (4,  'Pham Thi Dung',     'STAFF'),
  (5,  'Vu Minh Duc',       'STAFF'),
  (6,  'Hoang Thi Lan',     'MANAGER'),
  (7,  'Dang Quoc Minh',    'MANAGER'),
  (8,  'Bui Thi Ngoc',      'ADMIN'),
  (9,  'Doan Van Phu',      'STAFF'),
  (10, 'Ly Thi Quynh',      'STAFF')
ON CONFLICT (id) DO NOTHING;

SELECT setval(
  'employees_id_seq',
  GREATEST((SELECT COALESCE(MAX(id), 0) FROM employees), 10),
  true
);

-- ================================================================
-- 2. APP USERS - login accounts linked to employees
-- Default password is "password123" BCrypt-hashed (matches AuthService)
-- ================================================================
INSERT INTO app_users (id, email, password_hash, role, status, employee_id) VALUES
  (1,  'an.nguyen@vnmap.vn',     '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'STAFF',   'ACTIVE', 1),
  (2,  'binh.tran@vnmap.vn',     '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'STAFF',   'ACTIVE', 2),
  (3,  'cuong.le@vnmap.vn',      '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'STAFF',   'ACTIVE', 3),
  (4,  'dung.pham@vnmap.vn',     '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'STAFF',   'ACTIVE', 4),
  (5,  'duc.vu@vnmap.vn',        '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'STAFF',   'ACTIVE', 5),
  (6,  'lan.hoang@vnmap.vn',     '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'MANAGER', 'ACTIVE', 6),
  (7,  'minh.dang@vnmap.vn',     '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'MANAGER', 'ACTIVE', 7),
  (8,  'ngoc.bui@vnmap.vn',      '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'ADMIN',   'ACTIVE', 8),
  (9,  'phu.doan@vnmap.vn',      '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'STAFF',   'ACTIVE', 9),
  (10, 'quynh.ly@vnmap.vn',      '$2a$10$DowJonesIndustrialAverageXYZ.DummyHash', 'STAFF',   'INACTIVE', 10)
ON CONFLICT (id) DO NOTHING;

SELECT setval(
  'app_users_id_seq',
  GREATEST((SELECT COALESCE(MAX(id), 0) FROM app_users), 10),
  true
);

-- ================================================================
-- 3. CAMPAIGNS - 10 named campaigns linked to specific employees
-- ================================================================
INSERT INTO campaigns (id, name, status, objective, start_date, end_date, owner_employee_id) VALUES
  (1,  'Chien dich Ha Noi Q1',     'ACTIVE',    'Tang cuong nhan dien thuong hieu tai Ha Noi',
       CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE + INTERVAL '60 days', 6),
  (2,  'Chien dich HCM Q2',        'ACTIVE',    'Khao sat nhu cau hoc sinh tai TP.HCM',
       CURRENT_DATE - INTERVAL '45 days', CURRENT_DATE + INTERVAL '45 days', 7),
  (3,  'Workshop Da Nang',         'ACTIVE',    'Workshop gioi thieu san pham moi tai Da Nang',
       CURRENT_DATE - INTERVAL '15 days', CURRENT_DATE + INTERVAL '30 days', 6),
  (4,  'Chien dich Can Tho',       'ACTIVE',    'Quang ba dia phuong tai Can Tho',
       CURRENT_DATE - INTERVAL '60 days', CURRENT_DATE + INTERVAL '30 days', 7),
  (5,  'Chien dich Hai Phong',     'DRAFT',     'Tang cuong nhan dien tai Hai Phong',
       CURRENT_DATE + INTERVAL '7 days', CURRENT_DATE + INTERVAL '90 days', 8),
  (6,  'Chien dich Quang Ninh',    'ACTIVE',    'Khao sat tai Quang Ninh',
       CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE + INTERVAL '40 days', 6),
  (7,  'Chien dich Thanh Hoa',     'COMPLETED', 'Workshop tai Thanh Hoa',
       CURRENT_DATE - INTERVAL '90 days', CURRENT_DATE - INTERVAL '30 days', 7),
  (8,  'Chien dich Nghe An',       'ACTIVE',    'Quang ba tai Nghe An',
       CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE + INTERVAL '50 days', 8),
  (9,  'Chien dich Ha Tinh',       'DRAFT',     'Tang cuong nhan dien tai Ha Tinh',
       CURRENT_DATE + INTERVAL '14 days', CURRENT_DATE + INTERVAL '75 days', 6),
  (10, 'Chien dich Khanh Hoa',     'COMPLETED', 'Khao sat tai Khanh Hoa',
       CURRENT_DATE - INTERVAL '120 days', CURRENT_DATE - INTERVAL '60 days', 7)
ON CONFLICT (id) DO NOTHING;

SELECT setval(
  'campaigns_id_seq',
  GREATEST((SELECT COALESCE(MAX(id), 0) FROM campaigns), 10),
  true
);

-- ================================================================
-- 4. CAMPAIGN EVENTS - 3 events per campaign = 30 events
-- ================================================================
DO $$
DECLARE
  c_id BIGINT;
  evt_types TEXT[] := ARRAY['WORKSHOP', 'SURVEY', 'PRESENTATION'];
  evt_idx INT;
  province_record RECORD;
  province_codes TEXT[] := ARRAY['01', '08', '48', '31', '04'];
  p_idx INT;
BEGIN
  FOR c_id IN 1..10 LOOP
    FOR evt_idx IN 1..3 LOOP
      p_idx := ((c_id + evt_idx) % 5) + 1;
      IF NOT EXISTS (
        SELECT 1 FROM campaign_events
        WHERE campaign_id = c_id
          AND name = 'Event ' || c_id || '-' || evt_idx
      ) THEN
        INSERT INTO campaign_events (
          campaign_id, name, event_type, status,
          starts_at, ends_at, location_label, province_code
        )
        SELECT
          c_id,
          'Event ' || c_id || '-' || evt_idx,
          evt_types[evt_idx],
          CASE WHEN c_id IN (7, 10) THEN 'COMPLETED' ELSE 'UPCOMING' END,
          CURRENT_TIMESTAMP + ((c_id * 5) + evt_idx) * INTERVAL '1 day',
          CURRENT_TIMESTAMP + ((c_id * 5) + evt_idx) * INTERVAL '1 day' + INTERVAL '3 hours',
          'Tai tinh ' || province_codes[p_idx],
          province_codes[p_idx];
      END IF;
    END LOOP;
  END LOOP;
END $$;

-- ================================================================
-- 5. EVENT SCHOOLS - link ~3 schools per event
-- Uses the schools already present in the DB.
-- ================================================================
DO $$
DECLARE
  evt RECORD;
  inserted_count INT;
  target_count CONSTANT INT := 3;
BEGIN
  FOR evt IN
    SELECT e.id AS event_id, e.province_code
    FROM campaign_events e
    WHERE NOT EXISTS (
      SELECT 1 FROM event_schools es WHERE es.event_id = e.id
    )
  LOOP
    INSERT INTO event_schools (event_id, school_uid)
    SELECT evt.event_id, s.school_uid
    FROM schools s
    WHERE s.province_code = evt.province_code
    ORDER BY random()
    LIMIT target_count;

    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    -- If no province-scoped schools, fall back to any schools
    IF inserted_count = 0 THEN
      INSERT INTO event_schools (event_id, school_uid)
      SELECT evt.event_id, s.school_uid
      FROM schools s
      ORDER BY random()
      LIMIT target_count;
    END IF;
  END LOOP;
END $$;

-- ================================================================
-- 6. EVENT ASSIGNMENTS - assign 2 staff per event
-- ================================================================
DO $$
DECLARE
  evt RECORD;
  staff_record RECORD;
  staff_idx INT := 0;
BEGIN
  FOR evt IN
    SELECT e.id AS event_id
    FROM campaign_events e
    WHERE NOT EXISTS (
      SELECT 1 FROM event_assignments ea WHERE ea.event_id = e.id
    )
  LOOP
    staff_idx := 0;
    FOR staff_record IN
      SELECT id FROM employees WHERE role IN ('STAFF', 'MANAGER') ORDER BY id LIMIT 5
    LOOP
      IF staff_idx >= 2 THEN EXIT; END IF;
      INSERT INTO event_assignments (event_id, employee_id)
      VALUES (evt.event_id, staff_record.id)
      ON CONFLICT DO NOTHING;
      staff_idx := staff_idx + 1;
    END LOOP;
  END LOOP;
END $$;

-- ================================================================
-- 7. STUDENTS - specific named students distributed across schools
-- ================================================================
INSERT INTO students (id, school_uid, full_name, email, phone, grade, class_name)
SELECT
  gs,
  s.school_uid,
  'Hoc sinh ' || gs || ' - ' || s.school_name,
  'student' || gs || '@vnmap.vn',
  '09' || LPAD((gs % 100000000)::text, 8, '0'),
  'Lop ' || (10 + (gs % 3)),
  'A' || (gs % 4 + 1)
FROM generate_series(1, 200) AS gs
CROSS JOIN LATERAL (
  SELECT school_uid, school_name FROM schools ORDER BY random() LIMIT 1
) s
ON CONFLICT (id) DO NOTHING;

SELECT setval(
  'students_id_seq',
  GREATEST((SELECT COALESCE(MAX(id), 0) FROM students), 200),
  true
);

-- ================================================================
-- 8. INTERACTIONS - spread across 30 days for trend chart
-- Uses /tmp/gen_inter.sql for cleaner array handling
-- ================================================================
\i /tmp/gen_inter.sql

-- ================================================================
-- 9. STUDENT REGISTRATIONS - register ~5 students per campaign
-- ================================================================
INSERT INTO campaign_student_registrations (campaign_id, student_id, school_uid, status)
SELECT DISTINCT ON (c.id, s.id)
  c.id,
  s.id,
  s.school_uid,
  (ARRAY['REGISTERED', 'ATTENDED', 'PENDING', 'CANCELLED'])[1 + (s.id % 4)]
FROM campaigns c
CROSS JOIN LATERAL (
  SELECT id, school_uid FROM students ORDER BY random() LIMIT 5
) s
WHERE c.id <= 10
ON CONFLICT (campaign_id, student_id) DO NOTHING;
