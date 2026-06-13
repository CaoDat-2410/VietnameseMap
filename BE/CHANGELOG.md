# Changelog

## Breaking Changes in API v2

**Migration Date:** 2025-06-12
**Reason:** Vietnam 2025 Administrative Reform (Resolution 202/2025/QH15)

### Removed Endpoints (v1)

| Endpoint | Replacement |
|----------|-------------|
| `GET /api/v1/geo/districts?provinceCode=X` | `GET /api/v1/geo/provinces/{code}/communes` |
| `GET /api/v1/geo/wards?districtCode=X` | REMOVED (communes directly under provinces) |
| `GET /api/v1/geo/districts/{id}/wards-boundaries` | `GET /api/v1/geo/provinces/{code}/communes-boundaries` |

### New Endpoints (v2)

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/geo/provinces/{code}/communes` | List all communes in a province |
| `GET /api/v1/geo/provinces/{code}/communes-boundaries` | GeoJSON boundaries for map display |
| `GET /api/v1/geo/provinces/{code}/communes-paginated?page=1&size=100` | Paginated commune list |
| `GET /api/v1/geo/macro-regions/{name}/communes` | List communes by macro-region |

### New Entity Structure

**Old (GADM - 3 levels):**
- 63 provinces
- ~705 districts (intermediate level)
- ~10,600 wards

**New (HuggingFace Dataset - 2 levels):**
- 34 provinces (2025 reform)
- 3,321 communes (no intermediate district level)

### New Fields on AdministrativeUnit

| Field | Type | Description |
|--------|------|-------------|
| `areaKm2` | BigDecimal | Area in square kilometers |
| `population` | Long | Population count |
| `density` | BigDecimal | Population density |
| `capital` | String | Provincial capital |
| `address` | String | Address |
| `phone` | String | Phone number |
| `decree` | String | Governing decree |
| `decreeUrl` | String | Link to decree |
| `macroRegion` | String | Macro-region (e.g., "North Delta") |
| `nPredecessors` | Integer | Number of predecessor units |

### Migration Path

1. **Backup:** Old data archived in `backups/gadm_backup_*.sql`
2. **Backend:** Update entity/DTO/schema (see migration scripts)
3. **Database:** Run `BE/postgres/import_new.sh`
4. **Frontend:** Update Flutter models and API calls
5. **Cache:** Clear Redis `geo:*` keys and Flutter local cache

### References

- Dataset: https://huggingface.co/datasets/tmquan/sapnhap-bando-vn
- Legal basis: Resolution 202/2025/QH15 (12 June 2025)
- Old API contract: `BE/docs/OLD_API_CONTRACT.md`
