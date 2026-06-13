#!/usr/bin/env python3
"""
Validation script for HuggingFace Vietnam administrative dataset.
Run before import (--pre-import) or after import (--post-import).
"""

import argparse
import sys

def run_pre_import_validation():
    """Validate the HuggingFace dataset before importing."""
    print("=" * 60)
    print("PRE-IMPORT VALIDATION: HuggingFace Dataset")
    print("=" * 60)
    
    try:
        from datasets import load_dataset
        
        print("\nLoading dataset: tmquan/sapnhap-bando-vn...")
        ds = load_dataset("tmquan/sapnhap-bando-vn", split="train")
        
        # 1. Check total row count
        total_rows = len(ds)
        print(f"\n1. Total rows: {total_rows}")
        if total_rows == 3355:
            print("   ✓ Expected 3,355 rows (34 provinces + 3,321 communes)")
        else:
            print(f"   ⚠ Unexpected row count: {total_rows}")
        
        # 2. Check for required columns
        required_cols = ['code', 'name', 'level', 'parent_code', 'boundary', 'macro_region']
        print(f"\n2. Column check:")
        for col in required_cols:
            if col in ds.column_names:
                print(f"   ✓ {col}")
            else:
                print(f"   ✗ {col} - MISSING")
        
        # 3. Check province/commune split
        if 'level' in ds.column_names:
            provinces = ds.filter(lambda x: x['level'] == 'PROVINCE')
            communes = ds.filter(lambda x: x['level'] == 'COMMUNE')
            print(f"\n3. Level distribution:")
            print(f"   Provinces: {len(provinces)}")
            if len(provinces) == 34:
                print("   ✓ Expected 34 provinces")
            else:
                print(f"   ⚠ Unexpected province count: {len(provinces)}")
            
            print(f"   Communes: {len(communes)}")
            if len(communes) == 3321:
                print("   ✓ Expected 3,321 communes")
            else:
                print(f"   ⚠ Unexpected commune count: {len(communes)}")
        
        # 4. Check macro-regions
        if 'macro_region' in ds.column_names:
            macro_regions = set(ds['macro_region'])
            print(f"\n4. Macro-regions ({len(macro_regions)}):")
            for mr in sorted(macro_regions):
                if mr:
                    print(f"   - {mr}")
            
            if len(macro_regions) == 6:
                print("   ✓ Expected 6 macro-regions")
            else:
                print(f"   ⚠ Unexpected macro-region count: {len(macro_regions)}")
        
        # 5. Check for null geometries
        if 'boundary' in ds.column_names:
            null_boundaries = sum(1 for b in ds['boundary'] if b is None)
            print(f"\n5. Null geometries: {null_boundaries}")
            if null_boundaries == 0:
                print("   ✓ All rows have boundaries")
            else:
                print(f"   ⚠ {null_boundaries} rows missing boundaries")
        
        # 6. Check for duplicate codes
        if 'code' in ds.column_names:
            codes = ds['code']
            unique_codes = set(codes)
            duplicates = len(codes) - len(unique_codes)
            print(f"\n6. Duplicate codes: {duplicates}")
            if duplicates == 0:
                print("   ✓ No duplicate codes")
            else:
                print(f"   ✗ Found {duplicates} duplicate codes")
        
        # 7. Check commune-parent relationships
        if 'level' in ds.column_names and 'parent_code' in ds.column_names:
            communes = ds.filter(lambda x: x['level'] == 'COMMUNE')
            provinces = ds.filter(lambda x: x['level'] == 'PROVINCE')
            province_codes = set(provinces['code'])
            
            invalid_parents = 0
            for commune in communes:
                if commune['parent_code'] not in province_codes:
                    invalid_parents += 1
            
            print(f"\n7. Commune-parent relationships: {invalid_parents} invalid")
            if invalid_parents == 0:
                print("   ✓ All communes have valid parent provinces")
            else:
                print(f"   ⚠ {invalid_parents} communes have invalid parent codes")
        
        # 8. Population check (if available)
        if 'population' in ds.column_names:
            total_pop = sum(p for p in ds['population'] if p is not None)
            print(f"\n8. Total population: {total_pop:,}")
            expected_range = (107_825_000, 119_275_000)  # 113.5M ±5%
            if expected_range[0] <= total_pop <= expected_range[1]:
                print("   ✓ Population within expected range (107.8M - 119.3M)")
            else:
                print("   ⚠ Population outside expected range")
        
        print("\n" + "=" * 60)
        print("PRE-IMPORT VALIDATION COMPLETE")
        print("=" * 60)
        
    except ImportError:
        print("ERROR: datasets library not installed.")
        print("Install with: pip install datasets")
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)


def run_post_import_validation():
    """Validate data in PostgreSQL after import."""
    print("=" * 60)
    print("POST-IMPORT VALIDATION: Database Check")
    print("=" * 60)
    print("\nNote: This script assumes PostgreSQL is accessible.")
    print("Run database queries manually or integrate with your DB config.")
    
    print("\nRun these queries to validate:")
    print("-" * 40)
    
    print("""
-- 1. Check total counts
SELECT level, COUNT(*) FROM administrative_units GROUP BY level ORDER BY level;
-- Expected: PROVINCE=34, COMMUNE=3321

-- 2. Check all provinces have boundaries
SELECT COUNT(*) FROM administrative_units WHERE level = 'PROVINCE' AND boundary IS NULL;
-- Expected: 0

-- 3. Check all communes have valid parents
SELECT COUNT(*) FROM administrative_units a
WHERE a.level = 'COMMUNE'
AND NOT EXISTS (SELECT 1 FROM administrative_units p WHERE p.id = a.parent_id AND p.level = 'PROVINCE');
-- Expected: 0

-- 4. Check all macro-regions present
SELECT DISTINCT macro_region FROM administrative_units WHERE level = 'PROVINCE' ORDER BY macro_region;
-- Expected: 6 regions

-- 5. Check spatial index exists
SELECT indexname FROM pg_indexes WHERE tablename = 'administrative_units' AND indexname LIKE '%gist%';
-- Expected: idx_boundary_gist and idx_centroid_gist

-- 6. Check reverse geocode works
SELECT name FROM administrative_units 
WHERE ST_Contains(boundary, ST_SetSRID(ST_Point(105.8542, 21.0285), 4326));
-- Expected: commune name in Ba Dinh area
""")


def main():
    parser = argparse.ArgumentParser(description="Validate Vietnam administrative dataset")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--pre-import', action='store_true', help='Validate HuggingFace dataset before import')
    group.add_argument('--post-import', action='store_true', help='Show validation queries for database after import')
    
    args = parser.parse_args()
    
    if args.pre_import:
        run_pre_import_validation()
    elif args.post_import:
        run_post_import_validation()


if __name__ == "__main__":
    main()
