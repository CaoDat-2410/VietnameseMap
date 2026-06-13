# Province Code Mapping: GADM to HuggingFace Dataset (2025 Reform)

> **Legal Basis:** 
> - National Assembly Resolution 202/2025/QH15 (12 June 2025)
> - Standing Committee Resolution 2025 (16 June 2025)
> - Source: https://sapnhap.bando.com.vn/

## Overview

Vietnam's 2025 administrative reform reduced provinces from 63 to 34 through mergers.

| Metric | Old (GADM) | New (HuggingFace) |
|--------|------------|-------------------|
| Provinces | 63 | 34 |
| Districts | ~705 | REMOVED |
| Wards/Communes | ~10,600 | 3,321 |

## Changes

### Provinces Merged/Consolidated

The following table documents provinces that were merged (old → new):

| Old Province | Merged Into | Notes |
|--------------|-------------|-------|
| Hà Nội (different boundary) | Hà Nội | Boundary expanded |
| Hồ Chí Minh | TP. Hồ Chí Minh | Slight boundary adjustments |
| Hải Phòng | Hải Phòng | Expanded |
| Đà Nẵng | Đà Nẵng | Expanded |
| Cần Thơ | Cần Thơ | Expanded |
| An Giang | An Giang | Retained |
| ... | ... | See HuggingFace dataset for complete list |

### Code Changes

**Old GADM Codes:** Numeric strings like `01`, `02`, etc.
**New Dataset Codes:** May use different format (check dataset schema)

### Level Enum Changes

```java
// Old
public enum UnitLevel {
    PROVINCE,
    DISTRICT,  // REMOVED
    WARD        // Renamed to COMMUNE
}

// New
public enum UnitLevel {
    PROVINCE,
    COMMUNE     // Replaces WARD
}
```

## Migration Notes

1. **Old district/ward queries will fail** - These entities no longer exist
2. **Province codes may differ** - Verify codes against new dataset
3. **Commune codes are new** - 3,321 communes, not 10,600 wards
4. **Parent relationships changed** - Communes now link directly to provinces

## New Entity Structure

```java
AdministrativeUnit {
    id: Long
    name: String
    code: String           // New codes from HuggingFace dataset
    level: PROVINCE | COMMUNE
    parentId: Long         // Province ID for communes
    boundary: GEOMETRY     // PostGIS polygon
    centroid: GEOMETRY     // Calculated
    
    // New fields
    areaKm2: BigDecimal
    population: Long
    density: BigDecimal
    capital: String
    address: String
    phone: String
    decree: String
    decreeUrl: String
    macroRegion: String    // e.g., "North Delta", "Mekong Delta"
    nPredecessors: Integer // Number of predecessor units
}
```

## API Changes

| Old Endpoint | New Endpoint | Notes |
|--------------|--------------|-------|
| `/districts?provinceCode=X` | `/provinces/{code}/communes` | Returns communes |
| `/wards?districtCode=X` | REMOVED | Direct province→commune only |
| `/districts/{id}/wards-boundaries` | `/provinces/{code}/communes-boundaries` | New endpoint |

## Verification

To verify the dataset structure:

```python
from datasets import load_dataset
ds = load_dataset("tmquan/sapnhap-bando-vn", split="train")
print(ds['code'][:5])        # Sample codes
print(set(ds['macro_region'])) # All 6 macro-regions
```

## References

- Dataset: https://huggingface.co/datasets/tmquan/sapnhap-bando-vn
- Legal source: https://sapnhap.bando.com.vn/
- Resolution: https://vanban.chinhphu.vn
