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
ogr2ogr -f PostgreSQL "PG:host=vnmap_postgres port=5432 dbname=vnmapdb user=postgres password=123456" "$GADM_FILE" \
    -sql "SELECT NAME_1 as name, GID_1 as code, 'PROVINCE' as level, geom FROM ADM_ADM_1" \
    -nln administrative_units -overwrite 2>&1
echo ""
echo "Step 3: Normalize province codes (replace dots with underscores)..."
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "UPDATE administrative_units SET code = REPLACE(code, '.', '_') WHERE level = 'PROVINCE';" 2>&1
echo ""
echo "Step 4: Import districts..."
ogr2ogr -f PostgreSQL "PG:host=vnmap_postgres port=5432 dbname=vnmapdb user=postgres password=123456" "$GADM_FILE" \
    -sql "SELECT NAME_2 as name, GID_1 || '_' || GID_2 as code, 'DISTRICT' as level, geom FROM ADM_ADM_2" \
    -nln administrative_units -append 2>&1
echo ""
echo "Step 5: Import wards..."
ogr2ogr -f PostgreSQL "PG:host=vnmap_postgres port=5432 dbname=vnmapdb user=postgres password=123456" "$GADM_FILE" \
    -sql "SELECT NAME_3 as name, GID_1 || '_' || GID_2 || '_' || GID_3 as code, 'WARD' as level, geom FROM ADM_ADM_3" \
    -nln administrative_units -append 2>&1
echo ""
echo "Step 6: Rename geom column to boundary..."
PGPASSWORD=123456 psql -h vnmap_postgres -U postgres -d vnmapdb -c "ALTER TABLE administrative_units RENAME COLUMN geom TO boundary;" 2>&1 || true
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
echo "Step 9: Calculate centroids..."
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
