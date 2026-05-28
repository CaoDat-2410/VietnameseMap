# Vietnam Map Backend API

A Spring Boot 3.x backend service for Vietnam administrative boundaries and weather data.

## Quick Start

```bash
cd BE

# Start all services (GADM data auto-imports on first run)
docker-compose up -d

# Wait for import to complete (~1-2 minutes)
docker logs -f vnmap_import
```

On first startup, the GADM Vietnam data is automatically imported from the local file (`gadm41_VNM.gpkg`).

## Services

| Service | Port | Description |
|---------|------|-------------|
| API | 8080 | Spring Boot backend |
| PostgreSQL | 5432 | Database with PostGIS |
| Redis | 6379 | Caching |

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
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v

# View import logs
docker logs -f vnmap_import

# View backend logs
docker logs -f vnmap_backend
```

## Manual Re-import

If you need to re-import the data:

```bash
docker exec vnmap_postgres psql -U postgres -d vnmapdb -c "DROP TABLE administrative_units;"
docker-compose restart import
```

## GADM Data

The GADM (Global Administrative Areas) database provides:
- **Provinces** (63 units)
- **Districts** (~710 units)
- **Wards** (~11,000 units)

Place the `gadm41_VNM.gpkg` file in the `BE` folder for auto-import.

## Documentation

- [Setup Guide](SETUP_GUIDE.md) - Detailed setup instructions
- [API Proposal](API_PROPOSAL.md) - Complete API documentation
