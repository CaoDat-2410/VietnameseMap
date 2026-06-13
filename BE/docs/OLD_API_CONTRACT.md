# Old GADM API Contract (v1 - Deprecated)

> **Status:** Archived as part of migration to HuggingFace dataset (2025 reform)
> **Archived:** 2025-06-12
> **Migration:** See CHANGELOG.md for new API v2 structure

## Old API Endpoints (v1)

### Provinces
```
GET /api/v1/geo/provinces
Response: List<AdministrativeUnitSummaryDto>
```

### Districts
```
GET /api/v1/geo/districts?provinceCode={code}
Response: List<AdministrativeUnitSummaryDto>
Note: REPLACED by /api/v1/geo/provinces/{code}/communes
```

### Wards
```
GET /api/v1/geo/wards?districtCode={code}
Response: List<AdministrativeUnitSummaryDto>
Note: REPLACED by commune-level queries
```

### Ward Boundaries
```
GET /api/v1/geo/districts/{districtId}/wards-boundaries
Response: List<GeoJsonFeatureDto>
Note: REPLACED by /api/v1/geo/provinces/{code}/communes-boundaries
```

### Boundaries
```
GET /api/v1/geo/provinces/{code}/boundary
GET /api/v1/geo/units/{code}/boundary
GET /api/v1/geo/provinces-boundaries
```

### Reverse Geocode
```
GET /api/v1/geo/reverse?lat={lat}&lng={lng}
Response: AdministrativeUnitDto (province, district, or ward)
```

## Old Data Structure (GADM)

| Level | Count | Description |
|-------|-------|-------------|
| PROVINCE | 63 | Old provincial structure (pre-2025 reform) |
| DISTRICT | ~705 | Intermediate level (REMOVED in 2025 reform) |
| WARD | ~10,600 | Ward/Commune level (now 3,321 communes) |

## Old Entity Fields

```java
AdministrativeUnit {
    id: Long
    name: String
    code: String (e.g., "01", "01_1", "01_1_1")
    level: PROVINCE | DISTRICT | WARD
    parentId: Long (foreign key to parent unit)
    boundary: GEOMETRY (PostGIS)
    centroid: GEOMETRY (Point)
}
```

## Backup Location

- Database backup: `BE/backups/gadm_backup_*.sql`
- Import script backup: `BE/postgres/import_gadm.sh`

## Migration Reference

- Old: 63 provinces → districts → wards (3-level hierarchy)
- New: 34 provinces → communes (2-level hierarchy)
- Legal basis: Resolution 202/2025/QH15 (12 June 2025)
