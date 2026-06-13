# Vietnam Map Backend API

A Spring Boot 3.x backend service for Vietnam administrative boundaries, weather,
and campaign/school outreach data.

## Quick Start

```bash
cd BE

# Build and start the full backend stack.
# This runs geo import, campaign school import, then starts the API.
docker compose up -d --build

# Watch import progress if needed.
docker logs -f vnmap_import
docker logs -f vnmap_campaign_import
```

On startup, the HuggingFace Vietnam administrative dataset is imported first.
The import container downloads province/commune GeoJSON boundaries directly
from HuggingFace, so large GeoJSON files do not need to be committed locally.
Then `import_data/Truong_THPT_2026_import_ready.xlsx` is imported into the
campaign school tables and dev seed data is created.

## Services

| Service | Port | Description |
|---------|------|-------------|
| API | 8080 | Spring Boot backend |
| PostgreSQL | 5432 | Database with PostGIS |
| Redis | 6379 | Caching |
| Import | - | One-shot geo import |
| Campaign Import | - | One-shot school/campaign seed import |

## API Endpoints

### Geo API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/geo/provinces` | Get all provinces |
| GET | `/api/v1/geo/districts?provinceCode=` | Get districts by province |
| GET | `/api/v1/geo/wards?districtCode=` | Get wards by district |
| GET | `/api/v1/geo/units/{code}` | Get unit details |

### Weather API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/weather?lat=&lng=` | Get weather by coordinates |

## Docker Commands

```bash
# Start backend stack
docker compose up -d --build

# Stop all services
docker compose down

# Stop and remove volumes (clean slate)
docker compose down -v

# View import logs
docker logs -f vnmap_import
docker logs -f vnmap_campaign_import

# View backend logs
docker logs -f vnmap_backend

# Optional test service
docker compose --profile test up test

# Optional SonarQube
docker compose --profile sonar up -d sonarqube
```

## Manual Re-import

If you need to re-import data without removing volumes:

```bash
docker compose run --rm import
docker compose run --rm campaign-import
```

## Data Sources

- `tmquan/sapnhap-bando-vn` from HuggingFace provides 34 provinces,
  3321 communes, committee locations, and boundaries.
- `import_data/Truong_THPT_2026_import_ready.xlsx` provides 4922 schools
  for campaign workflows.

The frontend no longer bundles `assets/geo/*.geojson`; it renders boundaries
from backend endpoints such as `/api/v1/geo/provinces-boundaries` and
`/api/v1/geo/units/{code}/boundary`.

## Documentation

- [Setup Guide](SETUP_GUIDE.md) - Detailed setup instructions
- [API Proposal](API_PROPOSAL.md) - Complete API documentation
