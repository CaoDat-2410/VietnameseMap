# Migration Verification Checklist

## Phase 4: Manual Verification

Complete these items after running the migration.

### Backend Verification

- [ ] **Database Data:**
  - [ ] Run: `SELECT level, COUNT(*) FROM administrative_units GROUP BY level;`
  - [ ] Expected: PROVINCE=34, COMMUNE=3321

- [ ] **API Endpoints:**
  - [ ] `GET /api/v1/geo/provinces` - returns 34 provinces
  - [ ] `GET /api/v1/geo/provinces/HN/communes` - returns communes for Hanoi
  - [ ] `GET /api/v1/geo/provinces/HN/communes-boundaries` - returns GeoJSON
  - [ ] `GET /api/v1/geo/provinces-boundaries` - returns FeatureCollection
  - [ ] `GET /api/v1/geo/reverse?lat=21.0285&lng=105.8542` - reverse geocode works

- [ ] **New Fields:**
  - [ ] `GET /api/v1/geo/units/HN` - includes `macroRegion`, `population`, `areaKm2`

- [ ] **Build:**
  - [ ] `mvn clean compile` succeeds
  - [ ] `mvn test` passes

### Frontend Verification

- [ ] **App Launch:**
  - [ ] App starts without errors
  - [ ] Province list displays correctly

- [ ] **Map:**
  - [ ] Map displays 34 province boundaries
  - [ ] Clicking province shows commune list
  - [ ] Commune boundaries load when zooming

- [ ] **Info Panel:**
  - [ ] Displays population, area, macro-region
  - [ ] Handles null values gracefully

- [ ] **Reverse Geocode:**
  - [ ] Returns commune-level results

### Cache Verification

- [ ] **Redis Cache:**
  - [ ] Old geo cache keys cleared
  - [ ] New requests populate cache correctly

- [ ] **Flutter Cache:**
  - [ ] Old cache version cleared
  - [ ] New cache version marked

### Rollback (if needed)

```bash
# Restore database from backup
psql vn_map < backups/pre_gadm_backup_20250612.sql

# Restart application to reload cache
```

---

## Sign-off

Migration verified by: _________________
Date: _________________
Notes: _________________
