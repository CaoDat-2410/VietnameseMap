# Vietnam Map Backend - Setup Guide

## Prerequisites

| Software | Download |
|----------|----------|
| Docker Desktop | [Docker](https://www.docker.com/products/docker-desktop/) |

## Quick Start

### 1. Clone and Navigate to Project

```bash
cd BE
```

### 2. Setup Environment Variables

```bash
# Copy example env file
cp .env.example .env
```

Edit `.env` and add your OpenWeatherMap API key:

```env
OWM_API_KEY=your_openweathermap_api_key_here
```

### 3. Download GADM Data (Optional)

The GADM data will be downloaded automatically if not found. To skip downloading, place the file in the BE folder:

```
BE/
└── gadm41_VNM.gpkg
```

Download from: https://geodata.ucdavis.edu/gadm/gadm4.1/gpkg/gadm41_VNM.gpkg

### 4. Start Services

```bash
docker-compose up -d
```

This will:
- Start **PostgreSQL** (PostGIS) on port 5432
- Start **Redis** on port 6379
- Start **Backend API** on port 8080
- Automatically import GADM Vietnam data on first startup

### 5. Verify Installation

```bash
# Health check
curl http://localhost:8080/actuator/health

# Get all provinces
curl http://localhost:8080/api/v1/geo/provinces
```

## GADM Data

The GADM (Global Administrative Areas) database provides:
- **Provinces** (63 units)
- **Districts** (~710 units)
- **Wards** (~11,000 units)

### Verify Data Import

```bash
docker logs -f vnmap_import
```

Check the count:

```bash
docker exec vnmap_postgres psql -U postgres -d vnmapdb -c "SELECT level, COUNT(*) FROM administrative_units GROUP BY level;"
```

Expected output:
```
   level    | count
-----------+-------
 DISTRICT  |   710
 PROVINCE  |    63
 WARD      | 11163
```

### Re-import Data

```bash
docker exec vnmap_postgres psql -U postgres -d vnmapdb -c "DROP TABLE administrative_units;"
docker-compose restart import
```

## Docker Commands Reference

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v

# View all logs
docker-compose logs -f

# View backend logs only
docker-compose logs -f backend

# View import logs
docker logs -f vnmap_import

# Restart backend only
docker-compose restart backend
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OWM_API_KEY` | OpenWeatherMap API key | (required) |
| `OWM_BASE_URL` | Weather API base URL | https://api.openweathermap.org |

## Quick Links

| Service | URL |
|---------|-----|
| API | http://localhost:8080/api/v1 |
| Swagger UI | http://localhost:8080/swagger-ui.html |
| Health | http://localhost:8080/actuator/health |

## Troubleshooting

### Docker Desktop Not Running

1. Start Docker Desktop from Start Menu
2. Wait for it to fully initialize (whale icon stable)
3. Run `docker-compose up -d` again

### Port Already in Use

```powershell
# Find process using port 8080
netstat -ano | Select-String ":8080"

# Kill process with PID
taskkill /PID <PID> /F
```

### Clean Reset

```bash
# Complete reset (deletes all data)
docker-compose down -v
docker-compose up -d
```
