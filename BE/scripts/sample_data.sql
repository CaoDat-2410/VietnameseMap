-- ================================================================
-- VN Map Campaign - Sample Data Generation Script
-- Run this AFTER seeding base data (users, provinces, communes)
-- ================================================================

-- PRE-REQUISITES:
-- 1. Run base seed: campaign-module.sql (creates tables, users, provinces)
-- 2. Ensure at least 5 users exist for owner_id references
-- 3. Ensure provinces table is populated (63 provinces)

-- ================================================================
-- 1. CAMPAIGNS - Exactly 10 campaigns
-- ================================================================
INSERT INTO campaigns (name, objective, status, start_date, end_date, owner_id)
SELECT
  name,
  objective,
  status,
  start_date,
  end_date,
  GREATEST(1, LEAST(
    (SELECT COUNT(*) FROM users WHERE active = true),
    (random() * 4 + 1)::int
  )) AS owner_id
FROM (
  VALUES
    ('Chiến dịch Hà Nội Q1', 'Tăng cường nhận diện thương hiệu tại Hà Nội', 'ACTIVE',
     CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE + INTERVAL '60 days'),
    ('Chiến dịch HCM Q2', 'Khảo sát nhu cầu học sinh tại TP.HCM', 'ACTIVE',
     CURRENT_DATE - INTERVAL '45 days', CURRENT_DATE + INTERVAL '45 days'),
    ('Workshop Đà Nẵng', 'Workshop giới thiệu sản phẩm mới tại Đà Nẵng', 'ACTIVE',
     CURRENT_DATE - INTERVAL '15 days', CURRENT_DATE + INTERVAL '30 days'),
    ('Chiến dịch Cần Thơ', 'Quảng bá địa phương tại Cần Thơ', 'ACTIVE',
     CURRENT_DATE - INTERVAL '60 days', CURRENT_DATE + INTERVAL '30 days'),
    ('Chiến dịch Hải Phòng', 'Tăng cường nhận diện tại Hải Phòng', 'DRAFT',
     CURRENT_DATE + INTERVAL '7 days', CURRENT_DATE + INTERVAL '90 days'),
    ('Chiến dịch Quảng Ninh', 'Khảo sát tại Quảng Ninh', 'ACTIVE',
     CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE + INTERVAL '40 days'),
    ('Chiến dịch Thanh Hóa', 'Workshop tại Thanh Hóa', 'DONE',
     CURRENT_DATE - INTERVAL '90 days', CURRENT_DATE - INTERVAL '30 days'),
    ('Chiến dịch Nghệ An', 'Quảng bá tại Nghệ An', 'ACTIVE',
     CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE + INTERVAL '50 days'),
    ('Chiến dịch Hà Tĩnh', 'Tăng cường nhận diện tại Hà Tĩnh', 'DRAFT',
     CURRENT_DATE + INTERVAL '14 days', CURRENT_DATE + INTERVAL '75 days'),
    ('Chiến dịch Khánh Hòa', 'Khảo sát tại Khánh Hòa', 'DONE',
     CURRENT_DATE - INTERVAL '120 days', CURRENT_DATE - INTERVAL '60 days')
) AS campaigns(name, objective, status, start_date, end_date);

-- ================================================================
-- 2. SCHOOLS - 50 schools spread across provinces
-- ================================================================
WITH province_list AS (
  SELECT code, province_name, latitude, longitude FROM provinces
),
school_provinces AS (
  SELECT gs, code, province_name, latitude, longitude,
         ROW_NUMBER() OVER (PARTITION BY gs) AS rn
  FROM generate_series(1, 50) AS gs
  JOIN province_list ON code::int = (gs % 63) + 1
)
INSERT INTO schools (school_uid, province_code, commune_code, school_code, school_name, address, area_type, latitude, longitude, geocode_status)
SELECT
  'SCH' || LPAD(gs::text, 4, '0') AS school_uid,
  code AS province_code,
  NULL AS commune_code,
  'SCH' || LPAD((gs + 100)::text, 3, '0') AS school_code,
  'Trường THPT ' || province_name || ' ' || gs AS school_name,
  province_name || ', Việt Nam' AS address,
  CASE
    WHEN code IN ('01', '79', '48') THEN 'KV1'
    WHEN code IN ('02', '03', '04') THEN 'KV2'
    ELSE 'KV3'
  END AS area_type,
  latitude + (random() - 0.5) * 0.3 AS latitude,
  longitude + (random() - 0.5) * 0.3 AS longitude,
  'APPROXIMATE' AS geocode_status
FROM school_provinces
WHERE rn = 1
LIMIT 50;

-- ================================================================
-- 3. EVENTS - ~100 events spread across campaigns
-- ================================================================
WITH campaign_list AS (
  SELECT id, name, start_date, end_date FROM campaigns LIMIT 10
),
event_counts AS (
  SELECT id, name, start_date, end_date,
         5 + (id % 6) AS num_events
  FROM campaign_list
),
event_series AS (
  SELECT
    c.id AS campaign_id,
    c.name || ' - ' || unnest(ARRAY['WORKSHOP', 'SURVEY', 'PRESENTATION', 'MEETING']) AS event_name,
    unnest(ARRAY['WORKSHOP', 'SURVEY', 'PRESENTATION', 'MEETING']) AS event_type,
    c.start_date + (gs * ((c.end_date - c.start_date)::int / NULLIF(c.num_events, 0))) AS event_date,
    p.code AS province_code,
    p.province_name
  FROM event_counts c
  CROSS JOIN LATERAL generate_series(1, c.num_events) AS gs
  LEFT JOIN provinces p ON p.code::int = (c.id % 63) + 1
)
INSERT INTO campaign_events (campaign_id, name, event_type, status, event_date, location_label, province_code)
SELECT
  campaign_id,
  event_name,
  event_type,
  CASE WHEN event_date < CURRENT_DATE THEN 'COMPLETED' ELSE 'UPCOMING' END,
  event_date,
  'Tại ' || province_name,
  province_code
FROM event_series
LIMIT 100;

-- ================================================================
-- 4. INTERACTIONS - 500+ interactions
-- ================================================================
INSERT INTO interactions (event_id, school_uid, participant_type, participant_id, channel, outcome, notes, created_at)
SELECT
  e.id,
  s.school_uid,
  CASE (random() * 2)::int
    WHEN 0 THEN 'STUDENT'
    WHEN 1 THEN 'PARENT'
    ELSE 'TEACHER'
  END,
  (random() * 1000)::int + 1,
  (ARRAY['PHONE', 'EMAIL', 'ZALO', 'VISIT', 'EVENT'])[1 + (random() * 4)::int],
  CASE
    WHEN random() < 0.4 THEN 'SUCCESSFUL'
    WHEN random() < 0.7 THEN 'FOLLOW_UP'
    ELSE 'NO_RESPONSE'
  END,
  'Interaction notes for testing',
  CURRENT_TIMESTAMP - (random() * 90)::int * INTERVAL '1 day'
FROM campaign_events e
CROSS JOIN LATERAL (
  SELECT school_uid FROM schools
  WHERE province_code = e.province_code
  LIMIT 1
) s
CROSS JOIN LATERAL generate_series(1, 1 + (random() * 4)::int) AS gs(n)
WHERE e.status = 'COMPLETED'
LIMIT 500;

-- ================================================================
-- 5. STUDENT REGISTRATIONS
-- ================================================================
INSERT INTO campaign_student_registrations (campaign_id, student_id, school_uid, registration_date, status)
SELECT
  c.id,
  gs AS student_id,
  s.school_uid,
  c.start_date + (random() * (c.end_date - c.start_date))::int,
  (ARRAY['REGISTERED', 'ATTENDED', 'CANCELLED', 'PENDING'])[1 + (random() * 3)::int]
FROM campaigns c
CROSS JOIN LATERAL generate_series(1, 1 + (random() * 20)::int) AS gs
CROSS JOIN LATERAL (
  SELECT school_uid FROM schools LIMIT 1
) s
WHERE c.id <= 10
LIMIT 200;

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================
-- SELECT 'Campaigns:' AS info, COUNT(*) AS count FROM campaigns;
-- SELECT 'Schools:' AS info, COUNT(*) AS count FROM schools;
-- SELECT 'Events:' AS info, COUNT(*) AS count FROM campaign_events;
-- SELECT 'Interactions:' AS info, COUNT(*) AS count FROM interactions;
-- SELECT 'Student Registrations:' AS info, COUNT(*) AS count FROM campaign_student_registrations;
