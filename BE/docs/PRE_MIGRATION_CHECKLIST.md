# Pre-Migration Checklist

> Complete all items before starting any code changes for the HuggingFace dataset migration.

## Phase 0.2 Environment Audit

### HuggingFace Access Check

- [x] **HuggingFace Dataset Accessible:**
  ```bash
  curl -I https://huggingface.co/datasets/tmquan/sapnhap-bando-vn/resolve/main/data/provinces.parquet
  # Should return HTTP 200
  ```
  - CI/CD environment network egress verified (some environments block huggingface.co)
  - Alternative: Download dataset locally if network restrictions exist

### Redis/Cache Check

- [x] **Redis Configuration Confirmed:**
  - [x] `RedisConfig.java` inspected
  - [x] Geo cache configured: `geo` cache with 1-hour TTL
  - [x] Cache key patterns documented (see below)
  - [x] No cache warming on startup detected
  - [x] Weather cache separate: `weather:` prefix (10-min TTL)

**Documented Geo Cache Keys:**
```
geo:provinces
geo:districts:{provinceCode}
geo:wards:{districtCode}
geo:boundary:{code}
geo:reverse:{lat}:{lng}
geo:allProvincesBoundaries
```

**Action Required:** Before migration, clear all `geo:*` keys:
```bash
redis-cli KEYS "geo:*" | xargs redis-cli DEL
```

### Flutter Local Cache Check

- [ ] **Flutter Local Data Source Check Required:**
  - [ ] Inspect `GeoLocalDataSource` in Flutter project for SQLite/Hive/SharedPreferences caching
  - [ ] Document any cached location data
  - [ ] Define cache versioning strategy (geo_cache_v1 → geo_cache_v2)

### Foreign Key Check

- [ ] **FK Dependencies on administrative_units:**
  ```sql
  SELECT table_name, constraint_name
  FROM information_schema.table_constraints
  WHERE constraint_type = 'FOREIGN KEY'
  AND referenced_table_name = 'administrative_units';
  ```
  - [ ] FK dependents found: ___ (list tables)
  - [ ] Cascade delete impact assessed:
    - [ ] Acceptable: dependent rows are derived data (will re-import)
    - [ ] Not acceptable: dependent rows contain user data (preserve)
  - [ ] Resolution: Use `TRUNCATE CASCADE` OR `DELETE FROM administrative_units`

### Backup Verification

- [x] **Database Backup Location Ready:**
  - [x] Backup folder created: `BE/backups/`
  - [ ] Backup command to run before migration:
    ```bash
    pg_dump vn_map > backups/pre_gadm_backup_$(date +%Y%m%d).sql
    ```
  - [ ] Backup file exists and size verified

### Data Quality Pre-Check

- [ ] **Macro-Region Data Quality:**
  ```python
  from datasets import load_dataset
  ds = load_dataset("tmquan/sapnhap-bando-vn", split="train")
  print(set(ds["macro_region"]))  # Should show 6 distinct macro-region names
  ```
  - [ ] Exactly 6 macro-regions found
  - [ ] No inconsistencies (e.g., "Mekong" vs "CuuLong" vs "ĐBSCL")

---

## Sign-off

All items above completed by: _________________
Date: _________________
Notes: _________________
