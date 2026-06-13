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
import traceback
from datetime import datetime

import psycopg2
from datasets import load_dataset

BATCH_SIZE = 500
SIMPLIFY_TOLERANCE = 0.0001
ROLLBACK_ON_ERROR = False  # Keep data even on non-critical warnings (orphan committees are dataset artifacts)
DB_CONFIG = {
    "host": "vnmap_postgres",
    "port": 5432,
    "dbname": "vnmapdb",
    "user": "postgres",
    "password": "123456",
}


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
        boundary_wkt = _normalize_wkt(row.get("wkt"))
        centroid_wkt = _build_point_wkt(row.get("centroid_lon"), row.get("centroid_lat"))

        cur.execute("""
            INSERT INTO administrative_units
                (kind, code, name, type, parent_code,
                 area_km2, population, density, capital,
                 centroid_lon, centroid_lat, boundary, centroid,
                 decree, decree_url, macro_region, n_predecessors, predecessors,
                 updated_at)
            VALUES (%s, %s, %s, %s, NULL,
                    %s, %s, %s, %s,
                    %s, %s,
                    %s,
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
                boundary       = EXCLUDED.boundary,
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
             OR administrative_units.boundary   IS DISTINCT FROM EXCLUDED.boundary;
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
            boundary_wkt,
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
    """Import communes with parent_code = province.code. Shapely pre-simplifies polygons."""
    from shapely import wkt as shapely_wkt

    cur = conn.cursor()
    count = 0

    for row in ds:
        wkt_raw = row.get("wkt") or ""

        boundary_wkt = None
        if wkt_raw.strip().upper().startswith(("POLYGON", "MULTIPOLYGON")):
            try:
                geom = shapely_wkt.loads(wkt_raw)
                simplified = geom.simplify(SIMPLIFY_TOLERANCE, preserve_topology=True)
                boundary_wkt = simplified.wkt
            except Exception:
                boundary_wkt = wkt_raw

        centroid_wkt = _build_point_wkt(row.get("centroid_lon"), row.get("centroid_lat"))

        cur.execute("""
            INSERT INTO administrative_units
                (kind, code, name, type, parent_code,
                 area_km2, population, density,
                 centroid_lon, centroid_lat, boundary, centroid,
                 decree, decree_url, macro_region, n_predecessors, predecessors,
                 updated_at)
            VALUES ('commune', %s, %s, %s, %s,
                    %s, %s, %s,
                    %s, %s,
                    %s,
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
                boundary       = EXCLUDED.boundary,
                centroid       = EXCLUDED.centroid,
                updated_at     = CURRENT_TIMESTAMP
            WHERE
                administrative_units.name        IS DISTINCT FROM EXCLUDED.name
             OR administrative_units.parent_code IS DISTINCT FROM EXCLUDED.parent_code
             OR administrative_units.boundary    IS DISTINCT FROM EXCLUDED.boundary;
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
            boundary_wkt,
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
    checks.append(("orphaned_committees", orphaned_c, 0))

    cur.execute("""
        SELECT COUNT(*) FROM administrative_units
        WHERE boundary IS NOT NULL AND NOT ST_IsValid(boundary)
    """)
    invalid_geom = cur.fetchone()[0]
    checks.append(("invalid_geometries", invalid_geom, 0))

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


def _normalize_wkt(wkt: str | None) -> str | None:
    """Strip whitespace, return None for empty/None."""
    if not wkt:
        return None
    return wkt.strip()


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
        print("\n[1/6] Downloading datasets from HuggingFace...")
        ds_prov  = load_dataset("tmquan/sapnhap-bando-vn", "provinces",  trust_remote_code=True)["train"]
        ds_com   = load_dataset("tmquan/sapnhap-bando-vn", "communes",   trust_remote_code=True)["train"]
        ds_comm  = load_dataset("tmquan/sapnhap-bando-vn", "committees", trust_remote_code=True)["train"]
        print(f"  Loaded: {len(ds_prov)} provinces, {len(ds_com)} communes, {len(ds_comm)} committees")

        print("\n[2/6] Profiling datasets...")
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

        print("\n[3/6] Importing provinces...")
        n_prov = import_provinces(ds_prov, conn)
        print(f"  Imported {n_prov} provinces.")

        print("\n[4/6] Importing communes...")
        n_com = import_communes(ds_com, conn)
        print(f"  Imported {n_com} communes.")

        print("\n[5/6] Importing committees...")
        n_comm = import_committees(ds_comm, conn)
        print(f"  Imported {n_comm} committees.")

        print("\n[6/6] Running validation checks...")
        checks = run_validation(conn)
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
