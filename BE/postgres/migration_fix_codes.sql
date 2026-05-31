-- migration_fix_codes.sql
-- Fixes code format, centroid calculation, and parent relationships using PostGIS
-- Usage: Get-Content postgres/migration_fix_codes.sql | docker exec -i vnmap_postgres psql -U postgres -d vnmapdb

-- =============================================
-- STEP 1: Fix province codes (VNM.1_1 -> 1_1)
-- =============================================
UPDATE administrative_units
SET code = SUBSTRING(code FROM 5)
WHERE level = 'PROVINCE' AND code LIKE 'VNM.%';

-- =============================================
-- STEP 2: Fix district codes
-- Pattern: VNM.1_1.VNM.1.1_1 -> 1_1_1
-- =============================================
UPDATE administrative_units
SET code = REGEXP_REPLACE(
    REGEXP_REPLACE(code, 'VNM\.', '', 'g'),
    '\.', '_', 'g'
)
WHERE level = 'DISTRICT' AND code LIKE 'VNM.%';

-- =============================================
-- STEP 3: Fix ward codes
-- Pattern: VNM.1.1.1_1 -> 1_1_1
-- =============================================
UPDATE administrative_units
SET code = REGEXP_REPLACE(
    REGEXP_REPLACE(code, 'VNM\.', '', 'g'),
    '\.', '_', 'g'
)
WHERE level = 'WARD' AND code LIKE 'VNM.%';

-- =============================================
-- STEP 4: Clear all parent relationships
-- =============================================
UPDATE administrative_units SET parent_id = NULL;

-- =============================================
-- STEP 5: Re-link district -> province
-- District code: 1_1_1 (format: GID1_GID2_index_suffix)
-- Province code: 1_1 (format: GID1_suffix)
-- District starts with province code prefix
-- =============================================
UPDATE administrative_units d
SET parent_id = p.id
FROM administrative_units p
WHERE d.level = 'DISTRICT'
  AND p.level = 'PROVINCE'
  AND d.code LIKE p.code || '\_%' ESCAPE '\'
  AND d.parent_id IS NULL;

-- =============================================
-- STEP 6: Re-link ward -> district using PostGIS
-- Use ST_Contains to find which district contains each ward's centroid
-- =============================================
UPDATE administrative_units w
SET parent_id = d.id
FROM administrative_units w_geom
JOIN administrative_units d ON d.level = 'DISTRICT'
WHERE w_geom.id = w.id
  AND w.level = 'WARD'
  AND w.parent_id IS NULL
  AND d.boundary IS NOT NULL
  AND ST_Contains(d.boundary, ST_Centroid(w_geom.boundary));

-- =============================================
-- STEP 7: Calculate centroids
-- =============================================
UPDATE administrative_units
SET centroid = ST_Centroid(boundary)
WHERE centroid IS NULL AND boundary IS NOT NULL;

-- =============================================
-- SUMMARY
-- =============================================
\echo '=== Code Fix Summary ==='
SELECT level, COUNT(*) FROM administrative_units GROUP BY level ORDER BY level;
\echo 'Districts with parent:'
SELECT COUNT(*) FROM administrative_units WHERE level = 'DISTRICT' AND parent_id IS NOT NULL;
\echo 'Wards with parent:'
SELECT COUNT(*) FROM administrative_units WHERE level = 'WARD' AND parent_id IS NOT NULL;
\echo 'Units with centroid:'
SELECT COUNT(*) FROM administrative_units WHERE centroid IS NOT NULL;
\echo 'Sample province codes:'
SELECT code, name FROM administrative_units WHERE level = 'PROVINCE' ORDER BY name LIMIT 5;
\echo 'Sample district codes (first 10):'
SELECT d.code, d.name, p.name as province FROM administrative_units d JOIN administrative_units p ON d.parent_id = p.id WHERE d.level = 'DISTRICT' ORDER BY p.name LIMIT 10;
\echo 'Sample ward codes (first 10):'
SELECT w.code, w.name, d.name as district FROM administrative_units w JOIN administrative_units d ON w.parent_id = d.id WHERE w.level = 'WARD' ORDER BY d.name LIMIT 10;
