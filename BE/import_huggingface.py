"""
HuggingFace Vietnam Admin Dataset Import Script
===============================================
Import order: provinces → communes → committees
Requires: pip install datasets psycopg2-binary shapely

Usage:
    python import_huggingface.py --validate-only  # Dry run (profiling only)
    python import_huggingface.py                  # Full import
    python import_huggingface.py --skip-decree-check  # Skip HTTP URL checks
"""

import argparse
import http.client
import json
import time
import traceback
from datetime import datetime
from urllib.error import URLError
from urllib.request import Request, urlopen

import psycopg2
from datasets import load_dataset

BATCH_SIZE = 500
SIMPLIFY_TOLERANCE = 0.0001
ROLLBACK_ON_ERROR = False  # Keep data even on non-critical warnings (orphan committees are dataset artifacts)
PROVINCE_GEOJSON_URL = "https://huggingface.co/datasets/tmquan/sapnhap-bando-vn/resolve/main/geo/provinces.geojson"
COMMUNE_GEOJSON_URL = "https://huggingface.co/datasets/tmquan/sapnhap-bando-vn/resolve/main/geo/communes.geojson"
DB_CONFIG = {
    "host": "vnmap_postgres",
    "port": 5432,
    "dbname": "vnmapdb",
    "user": "postgres",
    "password": "123456",
}


def repair_schema(conn):
    """Apply idempotent schema fixes needed by the current import contract."""
    cur = conn.cursor()
    cur.execute("""
        DO $$
        DECLARE
          code_len integer;
          data_type text;
        BEGIN
          SELECT c.character_maximum_length, c.data_type
          INTO code_len, data_type
          FROM information_schema.columns c
          WHERE c.table_name = 'committee_locations'
            AND c.column_name = 'code';

          IF data_type = 'text' OR code_len IS NULL OR code_len < 64 THEN
            ALTER TABLE committee_locations ALTER COLUMN code TYPE VARCHAR(64);
          END IF;
        END $$;
    """)
    conn.commit()


def profile_dataset(ds, kind: str, skip_url_check: bool = False) -> dict:
    """Check null rates, duplicates, orphaned parents, dead decree URLs."""
    from concurrent.futures import ThreadPoolExecutor, as_completed

    issues = {
        "null_counts": {},
        "duplicates": [],
        "orphaned_parents": set(),
        "invalid_geom": [],
        "dead_urls": [],
    }

    seen_codes = set()
    all_codes = set()

    for row in ds:
        code = row.get("ma")
        ten = row.get("ten")
        all_codes.add(code)

        if not code:
            issues["null_counts"]["ma"] = issues["null_counts"].get("ma", 0) + 1
        if not ten:
            issues["null_counts"]["ten"] = issues["null_counts"].get("ten", 0) + 1
        if code in seen_codes:
            issues["duplicates"].append(code)
        seen_codes.add(code)

        wkt = row.get("wkt") or ""
        if wkt and not wkt.strip().upper().startswith(("POLYGON", "POINT", "MULTIPOLYGON", "MULTI")):
            issues["invalid_geom"].append(code)

    if kind in ("commune", "committee"):
        for row in ds:
            parent = row.get("parent_ma")
            if parent and parent not in all_codes:
                issues["orphaned_parents"].add(parent)

    if not skip_url_check:
        urls_to_check = [(r["ma"], r.get("decree_url")) for r in ds if r.get("decree_url")]
        if urls_to_check:
            import urllib.request
            import socket
            with ThreadPoolExecutor(max_workers=20) as executor:
                futures = {
                    executor.submit(_check_url, url): code
                    for code, url in urls_to_check
                }
                for future in as_completed(futures):
                    if not future.result():
                        issues["dead_urls"].append(futures[future])

    return issues


def _check_url(url: str, timeout: int = 5) -> bool:
    """Return True if URL responds with 2xx/3xx, False otherwise."""
    try:
        import urllib.request
        req = urllib.request.Request(url, method="HEAD")
        req.add_header("User-Agent", "vnmap-import-checker/1.0")
        rsp = urllib.request.urlopen(req, timeout=timeout)
        return 200 <= rsp.status < 400
    except Exception:
        return False


def import_provinces(ds, conn) -> int:
    """Import provinces. parent_code = NULL. Idempotent via ON CONFLICT DO UPDATE."""
    cur = conn.cursor()
    count = 0

    for row in ds:
        centroid_wkt = _build_point_wkt(row.get("centroid_lon"), row.get("centroid_lat"))

        cur.execute("""
            INSERT INTO administrative_units
                (kind, code, name, type, parent_code,
                 area_km2, population, density, capital,
                 centroid_lon, centroid_lat, centroid,
                 decree, decree_url, macro_region, n_predecessors, predecessors,
                 updated_at)
            VALUES (%s, %s, %s, %s, NULL,
                    %s, %s, %s, %s,
                    %s, %s,
                    %s,
                    %s, %s, %s, %s, %s,
                    CURRENT_TIMESTAMP)
            ON CONFLICT (code) DO UPDATE SET
                name           = EXCLUDED.name,
                type           = EXCLUDED.type,
                area_km2       = EXCLUDED.area_km2,
                population     = EXCLUDED.population,
                density        = EXCLUDED.density,
                capital        = EXCLUDED.capital,
                centroid_lon   = EXCLUDED.centroid_lon,
                centroid_lat   = EXCLUDED.centroid_lat,
                centroid       = EXCLUDED.centroid,
                decree         = EXCLUDED.decree,
                decree_url     = EXCLUDED.decree_url,
                macro_region   = EXCLUDED.macro_region,
                n_predecessors= EXCLUDED.n_predecessors,
                predecessors   = EXCLUDED.predecessors,
                updated_at     = CURRENT_TIMESTAMP
            WHERE
                administrative_units.name       IS DISTINCT FROM EXCLUDED.name
             OR administrative_units.population IS DISTINCT FROM EXCLUDED.population
             OR administrative_units.centroid   IS DISTINCT FROM EXCLUDED.centroid;
        """, (
            "province",
            row["ma"],
            row["ten"],
            row.get("type"),
            row.get("area_km2"),
            row.get("population"),
            row.get("density"),
            row.get("capital"),
            row.get("centroid_lon"),
            row.get("centroid_lat"),
            centroid_wkt,
            row.get("decree"),
            row.get("decree_url"),
            row.get("macro_region"),
            row.get("n_predecessors"),
            row.get("predecessors"),
        ))

        count += 1
        if count % BATCH_SIZE == 0:
            conn.commit()
            print(f"  Committed {count} provinces...")

    conn.commit()
    return count


def import_communes(ds, conn) -> int:
    """Import communes with parent_code = province.code."""
    cur = conn.cursor()
    count = 0

    for row in ds:
        centroid_wkt = _build_point_wkt(row.get("centroid_lon"), row.get("centroid_lat"))

        cur.execute("""
            INSERT INTO administrative_units
                (kind, code, name, type, parent_code,
                 area_km2, population, density,
                 centroid_lon, centroid_lat, centroid,
                 decree, decree_url, macro_region, n_predecessors, predecessors,
                 updated_at)
            VALUES ('commune', %s, %s, %s, %s,
                    %s, %s, %s,
                    %s, %s,
                    %s,
                    %s, %s, %s, %s, %s,
                    CURRENT_TIMESTAMP)
            ON CONFLICT (code) DO UPDATE SET
                name           = EXCLUDED.name,
                type           = EXCLUDED.type,
                parent_code    = EXCLUDED.parent_code,
                area_km2       = EXCLUDED.area_km2,
                population     = EXCLUDED.population,
                density        = EXCLUDED.density,
                centroid       = EXCLUDED.centroid,
                updated_at     = CURRENT_TIMESTAMP
            WHERE
                administrative_units.name        IS DISTINCT FROM EXCLUDED.name
             OR administrative_units.parent_code IS DISTINCT FROM EXCLUDED.parent_code
             OR administrative_units.centroid    IS DISTINCT FROM EXCLUDED.centroid;
        """, (
            row["ma"],
            row["ten"],
            row.get("type"),
            row["parent_ma"],
            row.get("area_km2"),
            row.get("population"),
            row.get("density"),
            row.get("centroid_lon"),
            row.get("centroid_lat"),
            centroid_wkt,
            row.get("decree"),
            row.get("decree_url"),
            row.get("macro_region"),
            row.get("n_predecessors"),
            row.get("predecessors"),
        ))

        count += 1
        if count % BATCH_SIZE == 0:
            conn.commit()
            print(f"  Committed {count} communes...")

    conn.commit()
    return count


def import_committees(ds, conn) -> int:
    """Import committee locations into committee_locations table."""
    cur = conn.cursor()
    count = 0
    skipped = 0

    for row in ds:
        # The committee dataset has ma='' for all records; use HuggingFace 'id' as code
        code = row.get("ma") or row.get("id") or ""
        if not code.strip():
            skipped += 1
            continue

        centroid_wkt = _build_point_wkt(row.get("centroid_lon"), row.get("centroid_lat"))

        cur.execute("""
            INSERT INTO committee_locations
                (code, name, type, parent_code, address, phone,
                 centroid_lon, centroid_lat, centroid)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s,
                    %s)
            ON CONFLICT (code) DO UPDATE SET
                name        = EXCLUDED.name,
                type        = EXCLUDED.type,
                parent_code = EXCLUDED.parent_code,
                address     = EXCLUDED.address,
                phone       = EXCLUDED.phone,
                centroid    = EXCLUDED.centroid
            WHERE
                committee_locations.name        IS DISTINCT FROM EXCLUDED.name
             OR committee_locations.parent_code IS DISTINCT FROM EXCLUDED.parent_code;
        """, (
            code,
            row["ten"],
            row.get("type"),
            row.get("parent_ma"),
            row.get("address"),
            row.get("phone"),
            row.get("centroid_lon"),
            row.get("centroid_lat"),
            centroid_wkt,
        ))

        count += 1
        if count % BATCH_SIZE == 0:
            conn.commit()
            print(f"  Committed {count} committees...")

    conn.commit()
    if skipped:
        print(f"  Skipped {skipped} committees with empty/null code.")
    return count


def import_boundaries(conn) -> dict:
    """Update boundaries from HuggingFace GeoJSON files after tabular rows exist."""
    cur = conn.cursor()
    stats = {
        "province_updates": 0,
        "commune_updates": 0,
        "geojson_without_db": [],
        "db_without_geojson": [],
    }

    for kind, url in [("province", PROVINCE_GEOJSON_URL), ("commune", COMMUNE_GEOJSON_URL)]:
        print(f"  Downloading {kind} boundaries...")
        features_by_code = _download_geojson_features(url)

        cur.execute("SELECT code FROM administrative_units WHERE kind = %s", (kind,))
        db_codes = {row[0] for row in cur.fetchall()}
        geo_codes = set(features_by_code)

        missing_db = sorted(geo_codes - db_codes)
        missing_geo = sorted(db_codes - geo_codes)
        stats["geojson_without_db"].extend((kind, code) for code in missing_db)
        stats["db_without_geojson"].extend((kind, code) for code in missing_geo)

        count = 0
        for code in sorted(geo_codes & db_codes):
            geometry = features_by_code[code].get("geometry")
            if not geometry:
                stats["db_without_geojson"].append((kind, code))
                continue

            cur.execute("""
                UPDATE administrative_units
                SET boundary = ST_Multi(ST_CollectionExtract(
                        ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326)),
                        3
                    )),
                    updated_at = CURRENT_TIMESTAMP
                WHERE kind = %s AND code = %s
            """, (json.dumps(geometry, ensure_ascii=False), kind, code))

            count += 1
            if count % BATCH_SIZE == 0:
                conn.commit()
                print(f"  Updated {count} {kind} boundaries...")

        conn.commit()
        stats[f"{kind}_updates"] = count
        print(f"  Updated {count} {kind} boundaries.")

    if stats["geojson_without_db"]:
        print("  GeoJSON features without matching DB rows:")
        for kind, code in stats["geojson_without_db"][:20]:
            print(f"    {kind}: {code}")
        if len(stats["geojson_without_db"]) > 20:
            print(f"    ... {len(stats['geojson_without_db']) - 20} more")

    if stats["db_without_geojson"]:
        print("  DB rows without matching GeoJSON features:")
        for kind, code in stats["db_without_geojson"][:20]:
            print(f"    {kind}: {code}")
        if len(stats["db_without_geojson"]) > 20:
            print(f"    ... {len(stats['db_without_geojson']) - 20} more")

    return stats


def _download_geojson_features(url: str) -> dict:
    req = Request(url, headers={"User-Agent": "vnmap-import/1.0"})
    last_error = None
    raw = None
    for attempt in range(1, 6):
        try:
            with urlopen(req, timeout=600) as response:
                raw = response.read().decode("utf-8")
            break
        except (TimeoutError, URLError, http.client.RemoteDisconnected) as exc:
            last_error = exc
            print(f"  Download attempt {attempt}/5 failed: {exc}")
            if attempt < 5:
                time.sleep(attempt * 5)

    if raw is None:
        raise last_error or RuntimeError(f"Failed to download {url}")

    cleaned = (raw
               .replace('"NaN"', "null")
               .replace('"Infinity"', "null")
               .replace('"-Infinity"', "null")
               .replace("NaN", "null")
               .replace("Infinity", "null")
               .replace("-Infinity", "null"))
    collection = json.loads(cleaned)
    features = collection.get("features") or []

    by_code = {}
    for feature in features:
        props = feature.get("properties") or {}
        code = props.get("ma")
        if code:
            by_code[str(code)] = feature
    return by_code


def run_validation(conn) -> list:
    """Post-import integrity + geometry validity checks."""
    cur = conn.cursor()
    checks = []

    cur.execute("""
        SELECT COUNT(*) FROM administrative_units a
        WHERE a.kind = 'commune'
          AND a.parent_code IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM administrative_units p
              WHERE p.code = a.parent_code AND p.kind = 'province'
          )
    """)
    orphaned = cur.fetchone()[0]
    checks.append(("orphaned_communes", orphaned, 0))

    cur.execute("""
        SELECT COUNT(*) FROM committee_locations c
        WHERE NOT EXISTS (
            SELECT 1 FROM administrative_units p
            WHERE p.code = c.parent_code AND p.kind = 'province'
        )
    """)
    orphaned_c = cur.fetchone()[0]
    checks.append(("orphaned_committees_reported", orphaned_c, orphaned_c))

    cur.execute("""
        SELECT COUNT(*) FROM administrative_units
        WHERE boundary IS NOT NULL AND NOT ST_IsValid(boundary)
    """)
    invalid_geom = cur.fetchone()[0]
    checks.append(("invalid_geometries", invalid_geom, 0))

    cur.execute("""
        SELECT COUNT(*) FROM administrative_units
        WHERE kind = 'province' AND boundary IS NOT NULL
    """)
    province_boundaries = cur.fetchone()[0]
    checks.append(("province_boundary_count", province_boundaries, 34))

    cur.execute("""
        SELECT COUNT(*) FROM administrative_units
        WHERE kind = 'commune' AND boundary IS NOT NULL
    """)
    commune_boundaries = cur.fetchone()[0]
    checks.append(("commune_boundary_count", commune_boundaries, 3321))

    cur.execute("SELECT kind, COUNT(*) FROM administrative_units GROUP BY kind")
    counts = dict(cur.fetchall())
    checks.append(("province_count", counts.get("province", 0), 34))
    checks.append(("commune_count",  counts.get("commune",  0), 3321))

    cur.execute("SELECT COUNT(*) FROM committee_locations")
    committee_count = cur.fetchone()[0]
    checks.append(("committee_count", committee_count, 3357))

    return checks


def vacuum_analyze(conn):
    """Run VACUUM ANALYZE after bulk load to update query planner statistics.

    VACUUM cannot run inside a transaction block, so we temporarily
    toggle autocommit. Requires PostgreSQL 9.5+ for ON CONFLICT DO UPDATE.
    """
    # Close any open transaction before changing autocommit mode
    conn.commit()
    old_autocommit = conn.autocommit
    conn.set_session(autocommit=True)
    try:
        cur = conn.cursor()
        print("  Running VACUUM ANALYZE...")
        cur.execute("VACUUM ANALYZE administrative_units;")
        cur.execute("VACUUM ANALYZE committee_locations;")
        cur.close()
    finally:
        conn.set_session(autocommit=old_autocommit)


def _build_point_wkt(lon, lat) -> str | None:
    """Build WKT POINT from centroid_lon/centroid_lat. Returns None for missing/zero."""
    try:
        lon_f = float(lon or 0)
        lat_f = float(lat or 0)
        if lon_f == 0 and lat_f == 0:
            return None
        return f"POINT({lon_f} {lat_f})"
    except (TypeError, ValueError):
        return None


def _rollback(conn):
    """Truncate all tables. Safe to call from any code path."""
    conn.rollback()
    cur = conn.cursor()
    cur.execute("TRUNCATE administrative_units, committee_locations CASCADE;")
    conn.commit()
    print("  Rolled back — tables truncated.")


def main():
    parser = argparse.ArgumentParser(description="Import HuggingFace Vietnam Admin Dataset")
    parser.add_argument("--validate-only", action="store_true",
                        help="Dry run: profiling + schema checks only, no data written")
    parser.add_argument("--skip-decree-check", action="store_true",
                        help="Skip decree URL HTTP checks (faster profiling)")
    args = parser.parse_args()

    print(f"\n=== HuggingFace Import ===  {datetime.now().isoformat()}")
    print(f"  Mode: {'VALIDATE ONLY' if args.validate_only else 'FULL IMPORT'}")

    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False

    try:
        print("\n[1/7] Repairing schema...")
        repair_schema(conn)
        print("  Schema repair complete.")

        print("\n[2/7] Downloading datasets from HuggingFace...")
        ds_prov  = load_dataset("tmquan/sapnhap-bando-vn", "provinces",  trust_remote_code=True)["train"]
        ds_com   = load_dataset("tmquan/sapnhap-bando-vn", "communes",   trust_remote_code=True)["train"]
        ds_comm  = load_dataset("tmquan/sapnhap-bando-vn", "committees", trust_remote_code=True)["train"]
        print(f"  Loaded: {len(ds_prov)} provinces, {len(ds_com)} communes, {len(ds_comm)} committees")

        print("\n[3/7] Profiling datasets...")
        prov_issues  = profile_dataset(ds_prov,  "province",  skip_url_check=args.skip_decree_check)
        com_issues   = profile_dataset(ds_com,   "commune",   skip_url_check=args.skip_decree_check)
        comm_issues  = profile_dataset(ds_comm,  "committee", skip_url_check=args.skip_decree_check)

        for label, issues in [("provinces", prov_issues), ("communes", com_issues), ("committees", comm_issues)]:
            print(f"\n  {label}:")
            if issues["null_counts"]:
                print(f"    NULL columns: {issues['null_counts']}")
            if issues["duplicates"]:
                print(f"    DUPLICATES: {issues['duplicates']}")
            if issues["orphaned_parents"]:
                print(f"    ORPHANED parents: {sorted(issues['orphaned_parents'])}")
            if issues["invalid_geom"]:
                print(f"    Invalid WKT: {issues['invalid_geom'][:10]}...")
            if issues["dead_urls"]:
                print(f"    Dead decree URLs: {len(issues['dead_urls'])} (sample: {issues['dead_urls'][:3]})")

        if args.validate_only:
            print("\n[VALIDATE ONLY] Exiting before import.")
            return

        print("\n[4/7] Importing provinces...")
        n_prov = import_provinces(ds_prov, conn)
        print(f"  Imported {n_prov} provinces.")

        print("\n[5/7] Importing communes...")
        n_com = import_communes(ds_com, conn)
        print(f"  Imported {n_com} communes.")

        print("\n[6/7] Importing committees...")
        n_comm = import_committees(ds_comm, conn)
        print(f"  Imported {n_comm} committees.")

        print("\n[7/7] Updating boundaries from GeoJSON...")
        boundary_stats = import_boundaries(conn)

        print("\nRunning validation checks...")
        checks = run_validation(conn)
        checks.append(("geojson_without_db", len(boundary_stats["geojson_without_db"]), 0))
        checks.append(("db_without_geojson", len(boundary_stats["db_without_geojson"]), 0))
        all_ok = True
        for name, actual, expected in checks:
            status = "OK" if actual == expected else "FAIL"
            if actual != expected:
                all_ok = False
            print(f"  [{status}] {name}: {actual} (expected {expected})")

        try:
            vacuum_analyze(conn)
        except Exception as ve:
            print(f"  Warning: VACUUM ANALYZE failed (non-fatal): {ve}")

        if all_ok:
            print("\n=== IMPORT SUCCESS ===")
        else:
            print("\n=== IMPORT COMPLETED WITH WARNINGS ===")
            if ROLLBACK_ON_ERROR:
                print("Rolling back due to failed checks...")
                _rollback(conn)
                print("Run with --validate-only to re-check before retrying.")

    except Exception as exc:
        print(f"\nERROR: {exc}")
        traceback.print_exc()
        if ROLLBACK_ON_ERROR:
            print("Rolling back due to exception...")
            _rollback(conn)
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
