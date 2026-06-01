# Vietnam Map + Weather API

**Base URL:** `http://localhost:8080/api/v1`
**Swagger UI:** `http://localhost:8080/swagger-ui.html`
**API Docs:** `http://localhost:8080/api-docs`

---

## 1. Geo APIs

### 1.1 Get All Provinces

**Endpoint:** `GET /api/v1/geo/provinces`

**Method:** `GET`
**Status:** `200 OK`

**Response:**
```json
{
  "success": true,
  "message": "Provinces retrieved successfully",
  "data": [
    {
      "code": "1_1",
      "name": "An Giang",
      "level": "PROVINCE",
      "parentId": null,
      "parentCode": null
    }
  ],
  "timestamp": "2026-05-31T11:02:30.889"
}
```

---

### 1.2 Get Districts by Province

**Endpoint:** `GET /api/v1/geo/districts`

**Method:** `GET`
**Status:** `200 OK`

| Parameter | Type | Location | Required | Description |
|-----------|------|---------|----------|-------------|
| provinceCode | string | query | Yes | Province code (e.g., `1_1`) |

**Example:** `GET /api/v1/geo/districts?provinceCode=1_1`

**Response:**
```json
{
  "success": true,
  "message": "Districts retrieved successfully",
  "data": [
    {
      "code": "1_1_1_2_1",
      "name": "Chợ Mới",
      "level": "DISTRICT",
      "parentId": 1,
      "parentCode": null
    }
  ]
}
```

---

### 1.3 Get Wards by District

**Endpoint:** `GET /api/v1/geo/wards`

**Method:** `GET`
**Status:** `200 OK`

| Parameter | Type | Location | Required | Description |
|-----------|------|---------|----------|-------------|
| districtCode | string | query | Yes | District code (e.g., `1_1_1_1_1`) |

**Example:** `GET /api/v1/geo/wards?districtCode=1_1_1_1_1`

**Response:**
```json
{
  "success": true,
  "message": "Wards retrieved successfully",
  "data": [
    {
      "code": "1_1_6_1",
      "name": "Nhơn Hội",
      "level": "WARD",
      "parentId": 79,
      "parentCode": null
    }
  ]
}
```

---

### 1.4 Get Administrative Unit by Code

**Endpoint:** `GET /api/v1/geo/units/{code}`

**Method:** `GET`
**Status:** `200 OK`

| Parameter | Type | Location | Required | Description |
|-----------|------|---------|----------|-------------|
| code | string | path | Yes | Province, district, or ward code |

**Example:** `GET /api/v1/geo/units/1_1`

**Response:**
```json
{
  "success": true,
  "message": "Unit retrieved successfully",
  "data": {
    "id": 1,
    "name": "An Giang",
    "code": "1_1",
    "level": "PROVINCE",
    "parentId": null,
    "parentCode": null,
    "centroidLat": 10.51132120487664,
    "centroidLng": 105.18275473791417,
    "childCount": 11
  }
}
```

---

### 1.5 Get Province Boundary

**Endpoint:** `GET /api/v1/geo/provinces/{code}/boundary`

**Method:** `GET`
**Status:** `200 OK`

| Parameter | Type | Location | Required | Description |
|-----------|------|---------|----------|-------------|
| code | string | path | Yes | Province code |

**Example:** `GET /api/v1/geo/provinces/1_1/boundary`

**Response:**
```json
{
  "success": true,
  "message": "Province boundary retrieved",
  "data": {
    "type": "Feature",
    "code": "1_1",
    "name": "An Giang",
    "level": "PROVINCE",
    "parentCode": null,
    "geometry": {
      "type": "MultiPolygon",
      "coordinates": [[[[105.54862213, 10.429475785], ...]]]
    }
  }
}
```

---

### 1.6 Get Unit Boundary

**Endpoint:** `GET /api/v1/geo/units/{code}/boundary`

**Method:** `GET`
**Status:** `200 OK`

| Parameter | Type | Location | Required | Description |
|-----------|------|---------|----------|-------------|
| code | string | path | Yes | Unit code (province, district, or ward) |

**Example:** `GET /api/v1/geo/units/1_1/boundary`

Returns GeoJSON Feature with boundary polygon for any administrative unit.

---

### 1.7 Reverse Geocode

**Endpoint:** `GET /api/v1/geo/reverse`

**Method:** `GET`
**Status:** `200 OK`

| Parameter | Type | Location | Required | Description |
|-----------|------|---------|----------|-------------|
| lat | double | query | Yes | Latitude (-90 to 90) |
| lng | double | query | Yes | Longitude (-180 to 180) |

**Example:** `GET /api/v1/geo/reverse?lat=21.0285&lng=105.8542`

**Response:**
```json
{
  "success": true,
  "message": "Reverse geocoding successful",
  "data": {
    "id": 234,
    "name": "Lý Thái Tổ",
    "code": "27_14_14_1",
    "level": "WARD",
    "parentId": 437,
    "parentCode": "27_1_27_14_1",
    "centroidLat": 21.03054474906241,
    "centroidLng": 105.85525776427964,
    "childCount": 0
  }
}
```

---

### 1.8 Calculate Centroids (Admin)

**Endpoint:** `POST /api/v1/geo/admin/calculate-centroids`

**Method:** `POST`
**Status:** `200 OK`

Recalculates centroid coordinates from boundary geometries for all units with NULL centroids.

**Response:**
```json
{
  "success": true,
  "message": "Calculated 0 centroids",
  "data": 0
}
```

---

## 2. Weather APIs

### 2.1 Get Weather by Coordinates

**Endpoint:** `GET /api/v1/weather`

**Method:** `GET`
**Status:** `200 OK`

| Parameter | Type | Location | Required | Description |
|-----------|------|---------|----------|-------------|
| lat | double | query | Yes | Latitude (-90 to 90) |
| lng | double | query | Yes | Longitude (-180 to 180) |

**Example:** `GET /api/v1/weather?lat=21&lng=105`

**Response:**
```json
{
  "success": true,
  "message": "Weather data (fresh)",
  "data": {
    "temperature": 28.25,
    "feelsLike": 32.4,
    "humidity": 78,
    "windSpeed": 0.81,
    "description": "mây cụm",
    "iconCode": "04d",
    "locationName": "Huyện Thanh Sơn",
    "pressure": 1006,
    "visibility": 10000,
    "tempMin": 28.25,
    "tempMax": 28.25,
    "timestamp": "2026-05-31T11:02:44Z",
    "source": "OpenWeatherMap",
    "cached": false
  }
}
```

---

### 2.2 Get Weather by Administrative Unit

**Endpoint:** `GET /api/v1/weather/unit/{unitCode}`

**Method:** `GET`
**Status:** `200 OK`

| Parameter | Type | Location | Required | Description |
|-----------|------|---------|----------|-------------|
| unitCode | string | path | Yes | Administrative unit code |

**Example:** `GET /api/v1/weather/unit/1_1`

Uses centroid coordinates of the unit to fetch weather from OpenWeatherMap.

**Response:**
```json
{
  "success": true,
  "message": "Weather data (fresh)",
  "data": {
    "temperature": 26.62,
    "feelsLike": 26.62,
    "humidity": 86,
    "windSpeed": 4.18,
    "description": "mưa nhẹ",
    "iconCode": "10d",
    "locationName": "An Giang",
    "pressure": 1008,
    "visibility": 10000,
    "tempMin": 26.62,
    "tempMax": 26.62,
    "timestamp": "2026-05-31T10:55:23Z",
    "source": "OpenWeatherMap",
    "cached": false
  }
}
```

---

### 2.3 Check Cache Status

**Endpoint:** `GET /api/v1/weather/cache`

**Method:** `GET`
**Status:** `200 OK`

| Parameter | Type | Location | Required | Description |
|-----------|------|---------|----------|-------------|
| lat | double | query | Yes | Latitude |
| lng | double | query | Yes | Longitude |

**Example:** `GET /api/v1/weather/cache?lat=21&lng=105`

**Response (cached):**
```json
{
  "success": true,
  "message": "Weather data found in cache",
  "data": { ... }
}
```

**Response (not cached):**
```json
{
  "success": true,
  "message": "No cached data available",
  "data": null
}
```

---

## 3. System APIs

### 3.1 Health Check

**Endpoint:** `GET /actuator/health`

**Method:** `GET`
**Status:** `200 OK`

**Response:**
```json
{"status": "UP"}
```

---

### 3.2 API Documentation

**Endpoint:** `GET /api-docs`
**Swagger UI:** `GET /swagger-ui.html`

---

## Code Format Reference

Administrative unit codes follow this format:

| Level | Format | Example |
|-------|--------|---------|
| Province | `{GID1}_{suffix}` | `1_1` |
| District | `{GID1}_{GID2}_{suffix}` | `1_1_1_1_1` |
| Ward | `{GID1}_{GID2}_{GID3}_{suffix}` | `1_1_6_1` |

---

## Database Record Counts

```
  level   | count
----------+-------
 DISTRICT |   710
 PROVINCE |    63
 WARD     | 11163
```

**Districts with parent:** 710
**Wards with parent:** 11,146 / 11,163
**Units with centroid:** 11,936

---

## CORS Configuration

Allowed origins:
- `http://localhost:3000`
- `http://localhost:5173`
- `http://127.0.0.1:3000`
- `http://127.0.0.1:5173`

Supported methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
