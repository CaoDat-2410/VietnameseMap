#!/usr/bin/env python3
"""
Import script for HuggingFace Vietnam administrative dataset (2025 reform).
Downloads data from HuggingFace and imports into PostgreSQL.

Usage:
    python import_new_dataset.py [--dry-run] [--host HOST] [--port PORT] [--dbname DBNAME] [--user USER] [--password PASSWORD]
"""

import argparse
import json
import sys
from pathlib import Path

try:
    from datasets import load_dataset
    import psycopg2
    from psycopg2.extras import execute_values
except ImportError as e:
    print(f"ERROR: Missing required package: {e}")
    print("Install with: pip install datasets psycopg2-binary")
    sys.exit(1)


def parse_args():
    parser = argparse.ArgumentParser(description="Import Vietnam administrative dataset")
    parser.add_argument('--dry-run', action='store_true', help='Validate but don\'t import')
    parser.add_argument('--host', default='vnmap_postgres', help='PostgreSQL host')
    parser.add_argument('--port', default='5432', help='PostgreSQL port')
    parser.add_argument('--dbname', default='vnmapdb', help='Database name')
    parser.add_argument('--user', default='postgres', help='Database user')
    parser.add_argument('--password', default='123456', help='Database password')
    return parser.parse_args()


def load_huggingface_data():
    """Load data from HuggingFace dataset."""
    print("Loading dataset from HuggingFace: tmquan/sapnhap-bando-vn")
    ds = load_dataset("tmquan/sapnhap-bando-vn", split="train")
    print(f"Loaded {len(ds)} records")
    return ds


def validate_data(ds):
    """Validate dataset before import."""
    print("\n--- Validation ---")
    
    errors = []
    
    # Check row count
    if len(ds) != 3355:
        errors.append(f"Unexpected row count: {len(ds)} (expected 3355)")
    else:
        print(f"✓ Row count: {len(ds)}")
    
    # Check columns
    required_cols = ['code', 'name', 'level', 'parent_code', 'boundary']
    for col in required_cols:
        if col not in ds.column_names:
            errors.append(f"Missing column: {col}")
        else:
            print(f"✓ Column '{col}' present")
    
    # Check level distribution
    if 'level' in ds.column_names:
        levels = {}
        for row in ds:
            level = row['level']
            levels[level] = levels.get(level, 0) + 1
        
        for level, count in levels.items():
            print(f"  {level}: {count}")
        
        if levels.get('PROVINCE', 0) != 34:
            errors.append(f"Unexpected province count: {levels.get('PROVINCE', 0)} (expected 34)")
        if levels.get('COMMUNE', 0) != 3321:
            errors.append(f"Unexpected commune count: {levels.get('COMMUNE', 0)} (expected 3321)")
    
    if errors:
        print("\n--- Validation Errors ---")
        for error in errors:
            print(f"✗ {error}")
        return False
    
    print("✓ All validations passed")
    return True


def get_db_connection(args):
    """Create database connection."""
    return psycopg2.connect(
        host=args.host,
        port=args.port,
        dbname=args.dbname,
        user=args.user,
        password=args.password
    )


def prepare_database(conn):
    """Prepare database for import (clear existing data)."""
    print("\n--- Preparing database ---")
    
    with conn.cursor() as cur:
        # Check for foreign keys
        cur.execute("""
            SELECT table_name, constraint_name
            FROM information_schema.table_constraints
            WHERE constraint_type = 'FOREIGN KEY'
            AND referenced_table_name = 'administrative_units'
        """)
        fk_tables = cur.fetchall()
        
        if fk_tables:
            print(f"Warning: Found {len(fk_tables)} tables with FK to administrative_units:")
            for table, constraint in fk_tables:
                print(f"  - {table}.{constraint}")
            print("Using TRUNCATE CASCADE to handle dependencies")
        
        # Clear existing data
        print("Clearing existing administrative_units data...")
        cur.execute("TRUNCATE administrative_units CASCADE;")
        conn.commit()
        
        print("✓ Database prepared")


def import_data(ds, conn, dry_run=False):
    """Import data into PostgreSQL."""
    print("\n--- Importing data ---")
    
    provinces = {}  # code -> id mapping
    
    with conn.cursor() as cur:
        # First pass: import provinces
        print("Importing provinces...")
        province_records = []
        for row in ds.filter(lambda x: x['level'] == 'PROVINCE'):
            boundary_json = json.dumps(row['boundary']) if row['boundary'] else None
            record = (
                row['name'],
                row['code'],
                'PROVINCE',
                None,  # parent_id
                boundary_json,
                row.get('area_km2'),
                row.get('population'),
                row.get('density'),
                row.get('capital'),
                row.get('address'),
                row.get('phone'),
                row.get('decree'),
                row.get('decree_url'),
                row.get('macro_region'),
                row.get('n_predecessors')
            )
            province_records.append(record)
        
        if dry_run:
            print(f"  [DRY RUN] Would insert {len(province_records)} provinces")
        else:
            cur.execute("""
                INSERT INTO administrative_units 
                (name, code, level, parent_id, boundary, area_km2, population, density, 
                 capital, address, phone, decree, decree_url, macro_region, n_predecessors)
                VALUES (%s, %s, %s, %s, ST_GeomFromGeoJSON(%s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id, code
            """, province_records)
            
            for row in cur.fetchall():
                provinces[row[1]] = row[0]
            
            conn.commit()
            print(f"  ✓ Imported {len(provinces)} provinces")
        
        # Second pass: import communes
        print("Importing communes...")
        commune_records = []
        for row in ds.filter(lambda x: x['level'] == 'COMMUNE'):
            parent_code = row.get('parent_code')
            parent_id = provinces.get(parent_code)
            
            if parent_id is None:
                print(f"  Warning: Commune '{row['code']}' has invalid parent code '{parent_code}'")
            
            boundary_json = json.dumps(row['boundary']) if row['boundary'] else None
            record = (
                row['name'],
                row['code'],
                'COMMUNE',
                parent_id,
                boundary_json,
                row.get('area_km2'),
                row.get('population'),
                row.get('density'),
                row.get('capital'),
                row.get('address'),
                row.get('phone'),
                row.get('decree'),
                row.get('decree_url'),
                row.get('macro_region'),
                row.get('n_predecessors')
            )
            commune_records.append(record)
        
        if dry_run:
            print(f"  [DRY RUN] Would insert {len(commune_records)} communes")
        else:
            cur.executemany("""
                INSERT INTO administrative_units 
                (name, code, level, parent_id, boundary, area_km2, population, density, 
                 capital, address, phone, decree, decree_url, macro_region, n_predecessors)
                VALUES (%s, %s, %s, %s, ST_GeomFromGeoJSON(%s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, commune_records)
            conn.commit()
            print(f"  ✓ Imported {len(commune_records)} communes")
        
        # Calculate centroids
        print("Calculating centroids...")
        if not dry_run:
            cur.execute("""
                UPDATE administrative_units 
                SET centroid = ST_Centroid(boundary)
                WHERE boundary IS NOT NULL AND centroid IS NULL
            """)
            conn.commit()
            print("  ✓ Centroids calculated")


def verify_import(conn):
    """Verify import results."""
    print("\n--- Verification ---")
    
    with conn.cursor() as cur:
        # Check counts
        cur.execute("SELECT level, COUNT(*) FROM administrative_units GROUP BY level ORDER BY level")
        print("Record counts:")
        for level, count in cur.fetchall():
            print(f"  {level}: {count}")
        
        # Check parent relationships
        cur.execute("""
            SELECT COUNT(*) FROM administrative_units a
            WHERE a.level = 'COMMUNE'
            AND NOT EXISTS (SELECT 1 FROM administrative_units p WHERE p.id = a.parent_id AND p.level = 'PROVINCE')
        """)
        invalid_parents = cur.fetchone()[0]
        if invalid_parents == 0:
            print("✓ All communes have valid parent provinces")
        else:
            print(f"⚠ {invalid_parents} communes have invalid parent references")
        
        # Check macro-regions
        cur.execute("SELECT DISTINCT macro_region FROM administrative_units WHERE level = 'PROVINCE' ORDER BY macro_region")
        macro_regions = [r[0] for r in cur.fetchall() if r[0]]
        print(f"\nMacro-regions ({len(macro_regions)}):")
        for mr in macro_regions:
            print(f"  - {mr}")


def main():
    args = parse_args()
    
    # Load and validate data
    ds = load_huggingface_data()
    
    if not validate_data(ds):
        print("\nValidation failed. Aborting import.")
        sys.exit(1)
    
    if args.dry_run:
        print("\n[DRY RUN] Skipping actual import")
        return
    
    # Connect to database
    try:
        conn = get_db_connection(args)
        print(f"\nConnected to {args.host}:{args.port}/{args.dbname}")
    except Exception as e:
        print(f"ERROR: Failed to connect to database: {e}")
        sys.exit(1)
    
    try:
        # Prepare database
        prepare_database(conn)
        
        # Import data
        import_data(ds, conn)
        
        # Verify
        verify_import(conn)
        
        print("\n" + "=" * 50)
        print("IMPORT COMPLETE")
        print("=" * 50)
        
    finally:
        conn.close()


if __name__ == "__main__":
    main()
