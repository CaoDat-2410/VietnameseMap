#!/bin/sh
echo "============================================="
echo "GADM Data Import Script"
echo "============================================="
echo "Waiting for PostgreSQL..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    if PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "\q" 2>/dev/null; then
        echo "PostgreSQL ready!"
        break
    fi
    echo "Waiting... ($i)"
    sleep 2
done
echo ""
echo "Step 1: Create/recreate table..."
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "
DROP TABLE IF EXISTS administrative_units CASCADE;
CREATE TABLE administrative_units (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    code VARCHAR(50),
    level VARCHAR(20),
    parent_id BIGINT,
    boundary GEOMETRY(Geometry, 4326),
    centroid GEOMETRY(Point, 4326)
);
CREATE INDEX idx_boundary ON administrative_units USING GIST(boundary);
CREATE INDEX idx_centroid ON administrative_units USING GIST(centroid);
" 2>&1
echo ""
echo "Checking for GADM file..."
if [ -f "/data/gadm41_VNM.gpkg" ]; then
    GADM_FILE="/data/gadm41_VNM.gpkg"
    echo "Using local file: $GADM_FILE"
else
    echo "Downloading GADM data..."
    curl -L -o /tmp/gadm41_VNM.gpkg https://geodata.ucdavis.edu/gadm/gadm4.1/gpkg/gadm41_VNM.gpkg
    GADM_FILE="/tmp/gadm41_VNM.gpkg"
fi
echo "File: $(ls -lh $GADM_FILE | awk '{print $5}')"
echo ""
echo "Step 2: Import provinces..."
# GID_1 = VNM.14_1 -> extract province number (chars between '.' and '_')
ogr2ogr -f PostgreSQL "PG:host=vnmap_postgres port=5432 dbname=vnmapdb user=postgres password=123456" "$GADM_FILE" \
    -sql "SELECT NAME_1 as name, SUBSTR(GID_1, INSTR(GID_1, '.')+1, INSTR(GID_1, '_')-INSTR(GID_1, '.')-1) as code, 'PROVINCE' as level, geom as boundary FROM ADM_ADM_1" \
    -nln administrative_units -append 2>&1
echo ""
echo "Step 3: Import districts..."
# GID_2 = VNM.14_1 -> province=14, district=1 -> code="14_1"
ogr2ogr -f PostgreSQL "PG:host=vnmap_postgres port=5432 dbname=vnmapdb user=postgres password=123456" "$GADM_FILE" \
    -sql "SELECT NAME_2 as name, SUBSTR(GID_2, INSTR(GID_2, '.')+1, INSTR(GID_2, '_')-INSTR(GID_2, '.')-1) || '_' || SUBSTR(GID_2, INSTR(GID_2, '_')+1) as code, 'DISTRICT' as level, geom as boundary FROM ADM_ADM_2" \
    -nln administrative_units -append 2>&1
echo ""
echo "Step 4: Import wards..."
# GID_2 = VNM.14.1_1, GID_3 = VNM.14.1_1.1 -> district code = "14_1" -> suffix after _ = "1"
# District code stored in DB: province_suffix + "_" + district_suffix (e.g. "1_1")
# Ward code = district_code before last "_" + "_" + district_suffix + "_" + ward_suffix
# Using regex: district code part = REGEXP_REPLACE(code, '_[^_]+$', '')
ogr2ogr -f PostgreSQL "PG:host=vnmap_postgres port=5432 dbname=vnmapdb user=postgres password=123456" "$GADM_FILE" \
    -sql "SELECT NAME_3 as name,
  SUBSTR(GID_2, INSTR(GID_2, '.')+1, INSTR(GID_2, '_')-INSTR(GID_2, '.')-1) || '_' ||
  SUBSTR(GID_2, INSTR(GID_2, '_')+1,
    CASE WHEN INSTR(SUBSTR(GID_2, INSTR(GID_2, '_')+1), '.') > 0
         THEN INSTR(SUBSTR(GID_2, INSTR(GID_2, '_')+1), '.') - 1
         ELSE LENGTH(SUBSTR(GID_2, INSTR(GID_2, '_')+1))
    END) || '_' ||
  SUBSTR(GID_3, INSTR(GID_3, '.')+1,
    CASE WHEN INSTR(SUBSTR(GID_3, INSTR(GID_3, '.')+1), '.') > 0
         THEN INSTR(SUBSTR(GID_3, INSTR(GID_3, '.')+1), '.') - 1
         ELSE LENGTH(SUBSTR(GID_3, INSTR(GID_3, '.')+1))
    END) as code,
  'WARD' as level, geom as boundary FROM ADM_ADM_3" \
    -nln administrative_units -append 2>&1
echo ""
echo "Step 5: Fix district codes (replace dot with underscore)..."
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "UPDATE administrative_units SET code = REPLACE(code, '.', '_') WHERE level = 'DISTRICT';" 2>&1
echo ""
echo "Step 6: Fix ward codes (replace dot with underscore)..."
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "UPDATE administrative_units SET code = REPLACE(code, '.', '_') WHERE level = 'WARD';" 2>&1
echo ""
echo "Step 7: Link district -> province relationships..."
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "
UPDATE administrative_units d
SET parent_id = p.id
FROM administrative_units p
WHERE d.level = 'DISTRICT'
  AND p.level = 'PROVINCE'
  AND d.code LIKE p.code || '\_%' ESCAPE '\'
  AND d.parent_id IS NULL;
" 2>&1
echo ""
echo "Step 8: Link ward -> district relationships..."
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "
UPDATE administrative_units w
SET parent_id = d.id
FROM administrative_units d
WHERE w.level = 'WARD'
  AND d.level = 'DISTRICT'
  AND w.code LIKE d.code || '\_%' ESCAPE '\'
  AND w.parent_id IS NULL;
" 2>&1
echo ""
echo "Step 9: Calculate centroids (ST_Centroid runs on PostgreSQL, not SQLite)..."
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "UPDATE administrative_units SET centroid = ST_Centroid(boundary) WHERE centroid IS NULL AND boundary IS NOT NULL;" 2>&1
echo ""
echo "============================================="
echo "Import Summary:"
echo "============================================="
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "SELECT level, COUNT(*) FROM administrative_units GROUP BY level ORDER BY level;" 2>&1
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "SELECT 'Districts with parent:', COUNT(*) FROM administrative_units WHERE level = 'DISTRICT' AND parent_id IS NOT NULL;" 2>&1
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "SELECT 'Wards with parent:', COUNT(*) FROM administrative_units WHERE level = 'WARD' AND parent_id IS NOT NULL;" 2>&1
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "SELECT 'Units with centroid:', COUNT(*) FROM administrative_units WHERE centroid IS NOT NULL;" 2>&1
echo ""
echo "Done!"
