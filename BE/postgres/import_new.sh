#!/bin/bash
set -e

echo "============================================="
echo "Vietnam Administrative Data Import"
echo "2025 Reform - HuggingFace Dataset"
echo "============================================="

# Configuration
DB_HOST=${DB_HOST:-vnmap_postgres}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-vnmapdb}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-123456}

# Wait for PostgreSQL
echo ""
echo "Waiting for PostgreSQL..."
for i in {1..30}; do
    if PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\q" 2>/dev/null; then
        echo "PostgreSQL ready!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 2
done

echo ""
echo "Step 1: Backup current data..."
mkdir -p backups
BACKUP_FILE="backups/pre_migration_$(date +%Y%m%d_%H%M%S).sql"
PGPASSWORD=$DB_PASSWORD pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"
echo "Backup saved to: $BACKUP_FILE"

echo ""
echo "Step 2: Validate new dataset..."
python scripts/validate_new_data.py --pre-import

echo ""
echo "Step 3: Run import script..."
python scripts/import_new_dataset.py --host "$DB_HOST" --port "$DB_PORT" --dbname "$DB_NAME" --user "$DB_USER" --password "$DB_PASSWORD"

echo ""
echo "Step 4: Verify import..."
PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT level, COUNT(*) FROM administrative_units GROUP BY level ORDER BY level;"

echo ""
echo "Step 5: Verify PostGIS indexes..."
PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT indexname FROM pg_indexes WHERE tablename = 'administrative_units' AND indexname LIKE '%gist%';"

echo ""
echo "============================================="
echo "Import complete!"
echo "============================================="
echo ""
echo "To test reverse geocoding:"
echo "  curl \"http://localhost:8080/api/v1/geo/reverse?lat=21.0285&lng=105.8542\""
echo ""
echo "To rollback if needed:"
echo "  psql -h $DB_HOST -U $DB_USER -d $DB_NAME < $BACKUP_FILE"
