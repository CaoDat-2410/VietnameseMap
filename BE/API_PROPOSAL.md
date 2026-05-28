# Vietnam Map + Weather API Proposal

**Version:** 1.0.0
**Last Updated:** 2026-05-28
**Base URL:** `http://localhost:8080/api/v1`

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Rate Limiting](#rate-limiting)
4. [Response Format](#response-format)
5. [Error Handling](#error-handling)
6. [Geo API Endpoints](#geo-api-endpoints)
7. [Weather API Endpoints](#weather-api-endpoints)
8. [Data Models](#data-models)

---

## Overview

This API provides two main services:

- **Geo API**: Administrative boundary data for Vietnam (provinces, districts, wards) with GeoJSON polygons
- **Weather API**: Real-time weather data from OpenWeatherMap with Redis caching

### Tech Stack

- **Framework**: Spring Boot 3.3.2 (Java 21)
- **Database**: PostgreSQL 16 + PostGIS 3.4
- **Cache**: Redis 7
- **API Documentation**: OpenAPI 3.0 / Swagger UI

### Base Configuration

| Environment | URL |
|------------|-----|
| Local Development | `http://localhost:8080/api/v1` |
| Production | `https://api.vnmap.com/api/v1` |

---

## Authentication

Currently, no authentication is required for public endpoints. The API is intended for client-side applications (Flutter mobile/web).

> **Note**: If authentication is needed in the future, JWT Bearer tokens will be implemented.

---

## Rate Limiting

| Tier | Limit | Window |
|------|-------|--------|
| Default | 100 requests | per minute |
| Weather | 60 requests | per minute |

Rate limit headers are included in responses:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Remaining requests in window
- `X-RateLimit-Reset`: Unix timestamp when limit resets

---

## Response Format

All responses follow a standard wrapper format:

### Success Response

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { ... },
  "timestamp": "2026-05-28T18:00:00"
}
```

### Error Response

```json
{
  "success": false,
  "message": "Error description",
  "timestamp": "2026-05-28T18:00:00",
  "status": 404,
  "error": "Not Found"
}
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Successful request |
| 400 | Bad Request | Invalid parameters or validation failed |
| 404 | Not Found | Resource does not exist |
| 500 | Internal Server Error | Unexpected server error |
| 502 | Bad Gateway | External service unavailable |

### Error Response Schema

```json
{
  "timestamp": "2026-05-28T18:00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "path": "/api/v1/geo/reverse",
  "validationErrors": {
    "lat": ["must be between -90 and 90"]
  }
}
```

---

## Geo API Endpoints

### Base Path: `/api/v1/geo`

### 1. Get All Provinces

**Endpoint:** `GET /provinces`

Retrieves a list of all provinces in Vietnam.

**Parameters:** None

**Response:**
```json
{
  "success": true,
  "message": "Provinces retrieved successfully",
  "data": [
    {
      "code": "01",
      "name": "Hà Nội",
      "level": "PROVINCE"
    },
    {
      "code": "79",
      "name": "Hồ Chí Minh",
      "level": "PROVINCE"
    }
  ]
}
```

---

### 2. Get Districts by Province

**Endpoint:** `GET /districts`

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| provinceCode | string | Yes | Province code (1-3 digits) |

**Example:** `GET /api/v1/geo/districts?provinceCode=01`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "code": "001",
      "name": "Ba Đình",
      "level": "DISTRICT",
      "parentId": 1
    }
  ]
}
```

---

### 3. Get Wards by District

**Endpoint:** `GET /wards`

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| districtCode | string | Yes | District code (2-6 digits) |

**Example:** `GET /api/v1/geo/wards?districtCode=001`

---

### 4. Get Administrative Unit by Code

**Endpoint:** `GET /units/{code}`

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| code | string | Yes | Unit code (province, district, or ward) |

**Example:** `GET /api/v1/geo/units/01`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "code": "01",
    "name": "Hà Nội",
    "level": "PROVINCE",
    "centroidLat": 21.0285,
    "centroidLng": 105.8542,
    "childCount": 30
  }
}
```

---

### 5. Get Unit Boundary (GeoJSON)

**Endpoint:** `GET /units/{code}/boundary`

Returns simplified GeoJSON polygon for map rendering.

**Example:** `GET /api/v1/geo/units/01/boundary`

**Response:**
```json
{
  "success": true,
  "data": {
    "type": "Feature",
    "code": "01",
    "name": "Hà Nội",
    "level": "PROVINCE",
    "geometry": {
      "type": "MultiPolygon",
      "coordinates": [[[[105.7, 20.9], ...]]]
    }
  }
}
```

---

### 6. Reverse Geocode

**Endpoint:** `GET /reverse`

Finds the administrative unit containing given GPS coordinates.

**Parameters:**

| Name | Type | Required | Range | Description |
|------|------|----------|-------|-------------|
| lat | double | Yes | -90 to 90 | Latitude |
| lng | double | Yes | -180 to 180 | Longitude |

**Example:** `GET /api/v1/geo/reverse?lat=21.0285&lng=105.8542`

**Response:**
```json
{
  "success": true,
  "data": {
    "code": "01",
    "name": "Hà Nội",
    "level": "PROVINCE",
    "centroidLat": 21.0285,
    "centroidLng": 105.8542
  }
}
```

---

## Weather API Endpoints

### Base Path: `/api/v1/weather`

### 1. Get Weather by Coordinates

**Endpoint:** `GET /`

**Parameters:**

| Name | Type | Required | Range | Description |
|------|------|----------|-------|-------------|
| lat | double | Yes | -90 to 90 | Latitude |
| lng | double | Yes | -180 to 180 | Longitude |

**Example:** `GET /api/v1/weather?lat=21.0285&lng=105.8542`

**Response:**
```json
{
  "success": true,
  "message": "Weather data (fresh)",
  "data": {
    "temperature": 28.5,
    "feelsLike": 31.2,
    "humidity": 75,
    "windSpeed": 3.5,
    "description": "mây thưa",
    "iconCode": "02d",
    "locationName": "Hanoi",
    "pressure": 1013,
    "visibility": 10000,
    "tempMin": 26.0,
    "tempMax": 30.0,
    "timestamp": "2026-05-28T17:00:00Z",
    "source": "OpenWeatherMap",
    "cached": false
  }
}
```

**Weather Icons:** `01d`, `01n`, `02d`, `02n`, `03d`, `03n`, `04d`, `04n`, `09d`, `09n`, `10d`, `10n`, `11d`, `11n`, `13d`, `13n`, `50d`, `50n`

---

### 2. Get Weather by Administrative Unit

**Endpoint:** `GET /unit/{unitCode}`

Retrieves weather for the centroid of an administrative unit.

**Example:** `GET /api/v1/weather/unit/01`

**Response:** Same structure as weather by coordinates.

---

### 3. Check Cache Status

**Endpoint:** `GET /cache`

Checks if weather data exists in Redis cache.

**Parameters:** Same as weather by coordinates.

**Response:**
```json
{
  "success": true,
  "message": "Weather data found in cache",
  "data": { ... }
}
```

---

## Data Models

### UnitLevel Enum

```json
{
  "PROVINCE": "Tỉnh/Thành phố",
  "DISTRICT": "Quận/Huyện/Thị xã",
  "WARD": "Xã/Phường/Thị trấn"
}
```

### GeoJSON Feature

GeoJSON follows the RFC 7946 specification:
- Type: `Feature`
- Geometry: `MultiPolygon` (WGS84, EPSG:4326)
- Simplified for performance based on zoom level

---

## Caching Strategy

| Data Type | Cache Name | TTL | Key Pattern |
|-----------|------------|-----|-------------|
| Provinces List | geo | 1 hour | `geo:provinces` |
| Districts List | geo | 1 hour | `geo:districts:{code}` |
| Wards List | geo | 1 hour | `geo:wards:{code}` |
| Unit Boundary | geo | 1 hour | `geo:boundary:{code}` |
| Weather Data | weather | 10 minutes | `weather:{lat}:{lng}` |

Weather coordinates are rounded to 2 decimal places (~1km precision) to increase cache hit rate.

---

## Performance Considerations

1. **Spatial Indexes**: GIST indexes on boundary and centroid columns
2. **Polygon Simplification**: ST_Simplify applied before returning GeoJSON
   - Province: tolerance 0.001 (~100m)
   - District: tolerance 0.0005 (~50m)
   - Ward: tolerance 0.0001 (~10m)
3. **Connection Pooling**: HikariCP with max 20 connections
4. **Redis Cache**: Reduces external API calls by 95%

---

## API Versioning

Current version: **v1**

Version is included in the URL path: `/api/v1/`

Breaking changes will result in a new version (v2, v3, etc.)

---

## SDK Examples

### Flutter (Dio)

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:8080/api/v1',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));

// Get provinces
final provinces = await dio.get('/geo/provinces');

// Get weather
final weather = await dio.get('/weather', queryParameters: {
  'lat': 21.0285,
  'lng': 105.8542,
});
```

### JavaScript (Fetch)

```javascript
const API_BASE = 'http://localhost:8080/api/v1';

// Get provinces
const provinces = await fetch(`${API_BASE}/geo/provinces`);
const { data } = await provinces.json();

// Get weather
const weather = await fetch(`${API_BASE}/weather?lat=21.0285&lng=105.8542`);
const { data } = await weather.json();
```

---

## Support & Documentation

- **Swagger UI**: `http://localhost:8080/swagger-ui.html`
- **OpenAPI JSON**: `http://localhost:8080/api-docs`
- **Health Check**: `http://localhost:8080/actuator/health`

---

## Changelog

### v1.0.0 (2026-05-28)

- Initial release
- Geo API with administrative boundaries
- Weather API with OpenWeatherMap integration
- Redis caching for performance
- PostGIS spatial queries
- SonarQube Quality Gate compliance
