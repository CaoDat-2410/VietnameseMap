# Vietnam Map + Campaign API

**Base URL:** `http://localhost:8080/api/v1`  
**Health:** `http://localhost:8080/actuator/health`  
**Swagger UI:** `http://localhost:8080/swagger-ui.html`  
**API Docs:** `http://localhost:8080/api-docs`

All application APIs return the shared wrapper:

```json
{
  "success": true,
  "message": "OK",
  "data": {}
}
```

JSON fields use `camelCase`.

---

## 1. Docker Runtime

Start the full backend stack:

```bash
cd BE
docker compose up -d --build
```

Default services:

| Service | Description |
| --- | --- |
| `postgres` | PostGIS database |
| `redis` | Redis cache |
| `import` | One-shot HuggingFace geo import |
| `campaign-import` | One-shot school Excel import + dev seed |
| `backend` | Spring Boot API |

The `import` service downloads `geo/provinces.geojson` and
`geo/communes.geojson` from HuggingFace at runtime and writes boundaries into
PostGIS. No local GeoJSON file is required in the Docker context.

Optional services:

```bash
docker compose --profile test up test
docker compose --profile sonar up -d sonarqube
```

Expected import counts:

| Dataset | Count |
| --- | ---: |
| Provinces | 34 |
| Communes | 3321 |
| Committee locations | 3357 |
| Schools | 4922 |
| Seed campaign interactions | 3 `INTERESTED` |

---

## 2. Geo APIs

### Get Provinces

`GET /api/v1/geo/provinces`

Returns all 34 post-2025 provinces.

### Get All Province Boundaries

`GET /api/v1/geo/provinces-boundaries`

Returns a GeoJSON `FeatureCollection` with 34 province features.

### Get Province Boundary

`GET /api/v1/geo/provinces/{code}/boundary`

Example:

```txt
GET /api/v1/geo/provinces/79/boundary
```

### Get Communes By Province

`GET /api/v1/geo/provinces/{code}/communes`

Example:

```txt
GET /api/v1/geo/provinces/79/communes
```

### Get Commune Boundaries By Province

`GET /api/v1/geo/provinces/{code}/communes-boundaries`

### Get Paginated Communes

`GET /api/v1/geo/provinces/{code}/communes-paginated?page=0&size=50`

### Get Administrative Unit

`GET /api/v1/geo/units/{code}`

### Get Administrative Unit Boundary

`GET /api/v1/geo/units/{code}/boundary`

### Reverse Geocode

`GET /api/v1/geo/reverse?lat={lat}&lng={lng}`

### Get Committee Locations

`GET /api/v1/geo/committees`

### Get Committee Locations By Province

`GET /api/v1/geo/committees/{provinceCode}`

---

## 3. Weather APIs

### Get Current Weather

`GET /api/v1/weather/current?lat={lat}&lng={lng}`

Returns weather data when `OWM_API_KEY` is valid. If OpenWeather fails, the API returns a structured error response instead of a blank payload.

### Get Weather By Unit

`GET /api/v1/weather/unit/{unitCode}`

Uses the administrative unit centroid.

---

## 4. School APIs

### Pagination Wrapper

School list endpoints return `ApiResponse<PagedResponse<SchoolDto>>`:

```json
{
  "success": true,
  "message": "Schools retrieved successfully",
  "data": {
    "items": [],
    "page": 0,
    "limit": 50,
    "totalItems": 4922,
    "totalPages": 99
  }
}
```

### Search Schools

`GET /api/v1/schools?page=0&limit=50&provinceCode=&communeCode=&area=&q=`

Query params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `page` | int | No | Default `0` |
| `limit` | int | No | Default `50`, max `200` |
| `provinceCode` | string | No | Province code |
| `communeCode` | string | No | Commune code |
| `area` | string | No | `KV1`, `KV2`, `KV2_NT`, `KV3` |
| `q` | string | No | Search school name/address |

`SchoolDto`:

```json
{
  "schoolUid": "01-066",
  "provinceCode": "01",
  "provinceName": "Hà Nội",
  "communeCode": "00004",
  "communeName": "Phường Ba Đình",
  "schoolCode": "066",
  "schoolName": "THPT Phan Đình Phùng",
  "address": "Số 30, phố Phan Đình Phùng, Phường Ba Đình, TP Hà Nội",
  "areaType": "KV3"
}
```

### Get School Detail

`GET /api/v1/schools/{schoolUid}`

Returns:

```json
{
  "school": {},
  "students": [],
  "persons": [],
  "relatives": []
}
```

Seed check:

```txt
GET /api/v1/schools/01-001
```

Expected seed detail includes 2 students, 1 teacher/person, and 2 relatives.

---

## 5. Campaign APIs

### Campaign DTO

```json
{
  "id": 1,
  "name": "Tư vấn tuyển sinh 2026",
  "status": "ACTIVE",
  "objective": "Thu thập nhu cầu tuyển sinh",
  "startDate": "2026-06-01",
  "endDate": "2026-07-31",
  "ownerEmployeeId": 2
}
```

### Create/Update Campaign Request

Writable fields are exactly:

```json
{
  "name": "Tư vấn tuyển sinh 2026",
  "status": "DRAFT",
  "objective": "Thu thập nhu cầu tuyển sinh",
  "startDate": "2026-06-01",
  "endDate": "2026-07-31",
  "ownerEmployeeId": 2
}
```

### List Campaigns

`GET /api/v1/campaigns`

### Create Campaign

`POST /api/v1/campaigns`

### Get Campaign

`GET /api/v1/campaigns/{id}`

### Update Campaign

`PUT /api/v1/campaigns/{id}`

### Get Campaign Dashboard

`GET /api/v1/campaigns/{id}/dashboard`

Seed check:

```txt
GET /api/v1/campaigns/1/dashboard
```

Expected fixture:

```json
{
  "campaignId": 1,
  "totalEvents": 2,
  "totalTargetSchools": 5,
  "totalAssignedEmployees": 3,
  "totalInteractions": 3,
  "interactionsByOutcome": {
    "INTERESTED": 3,
    "NOT_INTERESTED": 0,
    "FOLLOW_UP": 0
  },
  "interactionsByProvince": [
    {
      "provinceCode": "01",
      "provinceName": "Hà Nội",
      "totalInteractions": 3
    }
  ],
  "topSchools": [
    {
      "schoolUid": "01-001",
      "schoolName": "THPT Ba Vì",
      "totalInteractions": 2
    }
  ]
}
```

---

## 6. Event APIs

### Event DTO

```json
{
  "id": 10,
  "campaignId": 1,
  "name": "Tư vấn tại trường",
  "eventType": "SCHOOL_VISIT",
  "status": "PLANNED",
  "startsAt": "2026-06-20T08:00:00",
  "endsAt": "2026-06-20T11:00:00",
  "note": "Gặp BGH và học sinh khối 12"
}
```

### Create/Update Event Request

```json
{
  "name": "Tư vấn tại trường",
  "eventType": "SCHOOL_VISIT",
  "status": "PLANNED",
  "startsAt": "2026-06-20T08:00:00",
  "endsAt": "2026-06-20T11:00:00",
  "note": "Gặp BGH và học sinh khối 12"
}
```

### List Campaign Events

`GET /api/v1/campaigns/{id}/events`

### Create Campaign Event

`POST /api/v1/campaigns/{id}/events`

### Get Event

`GET /api/v1/events/{eventId}`

### Update Event

`PUT /api/v1/events/{eventId}`

---

## 7. Assignment APIs

### Assign School To Event

`POST /api/v1/events/{eventId}/schools`

```json
{
  "schoolUid": "01-001"
}
```

### Remove School From Event

`DELETE /api/v1/events/{eventId}/schools/{schoolUid}`

### Assign Employee To Event

`POST /api/v1/events/{eventId}/assignments`

```json
{
  "employeeId": 1
}
```

### Remove Employee From Event

`DELETE /api/v1/events/{eventId}/assignments/{employeeId}`

Phase 1 dev identity:

```txt
employeeId = 1
```

---

## 8. Interaction APIs

### Interaction DTO

```json
{
  "id": 100,
  "campaignId": 1,
  "eventId": 10,
  "employeeId": 1,
  "schoolUid": "01-001",
  "participantType": "STUDENT",
  "participantId": 1,
  "channel": "MEETING",
  "outcome": "INTERESTED",
  "note": "Quan tâm ngành CNTT",
  "nextFollowUpAt": "2026-06-25T09:00:00",
  "createdAt": "2026-06-20T08:45:00"
}
```

### List Event Interactions

`GET /api/v1/events/{eventId}/interactions`

Seed check:

```txt
GET /api/v1/events/1/interactions
```

Expected: 3 seed `INTERESTED` interactions.

### Create Interaction

`POST /api/v1/events/{eventId}/interactions`

```json
{
  "employeeId": 1,
  "schoolUid": "01-001",
  "participantType": "STUDENT",
  "participantId": 1,
  "channel": "MEETING",
  "outcome": "INTERESTED",
  "note": "Quan tâm ngành CNTT",
  "nextFollowUpAt": "2026-06-25T09:00:00"
}
```
