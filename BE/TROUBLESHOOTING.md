# Troubleshooting Guide

This guide covers common issues and their solutions.

## Table of Contents

1. [Build Issues](#build-issues)
2. [Database Issues](#database-issues)
3. [Redis Issues](#redis-issues)
4. [API Issues](#api-issues)
5. [Docker Issues](#docker-issues)

---

## Build Issues

### Java Version Mismatch

**Error:**
```
java.lang.UnsupportedClassVersionError: Unsupported major.minor version 65
```

**Solution:**
This means you're running Java < 21 but the project requires Java 21.

```bash
# Check Java version
java -version

# If on Windows, set JAVA_HOME
setx JAVA_HOME "C:\Program Files\Eclipse Adoptium\jdk-21.0.x.x"

# If on Linux/Mac, add to ~/.bashrc or ~/.zshrc
export JAVA_HOME=/path/to/jdk-21
export PATH=$JAVA_HOME/bin:$PATH
```

### Maven Build Fails with Dependency Errors

**Error:**
```
Could not resolve dependencies
```

**Solution:**

```bash
# Clear Maven cache
mvn dependency:purge-local-repository
mvn clean install -U

# Or clear manually
rm -rf ~/.m2/repository/com/vnmap
```

### Lombok Not Working

**Error:**
```
cannot find symbol: method builder()
```

**Solution:**

1. Ensure Lombok annotation processor is configured:

```xml
<!-- In pom.xml -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <annotationProcessorPaths>
            <path>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
                <version>1.18.32</version>
            </path>
        </annotationProcessorPaths>
    </configuration>
</plugin>
```

2. Install Lombok plugin in your IDE:
   - **IntelliJ**: Settings > Plugins > Marketplace > "Lombok"
   - **VS Code**: Install "Lombok Annotations Support" extension

---

## Database Issues

### PostgreSQL Connection Refused

**Error:**
```
Connection refused. Check that the hostname and port are correct
```

**Solution:**

1. Check if PostgreSQL container is running:
   ```bash
   docker ps | findstr postgres
   # or on Linux/Mac: docker ps | grep postgres
   ```

2. If not running, start it:
   ```bash
   docker-compose up -d postgres
   ```

3. Check container logs:
   ```bash
   docker logs vnmap_postgres
   ```

4. Verify port is not blocked:
   ```bash
   netstat -ano | findstr 5432
   ```

### Database Authentication Failed

**Error:**
```
FATAL: password authentication failed for user "vnmap"
```

**Solution:**

1. Check password in `.env` matches `docker-compose.yml`

2. If forgotten, reset by editing `docker-compose.yml`:
   ```yaml
   environment:
     POSTGRES_PASSWORD: new_password
   ```

3. Rebuild and restart:
   ```bash
   docker-compose down -v
   docker-compose up -d postgres
   ```

### Flyway Migration Failed

**Error:**
```
Migration V1__create_administrative_units.sql failed
```

**Solution:**

1. Check migration file syntax:
   ```bash
   # Connect to database
   psql -h localhost -U vnmap -d vnmapdb -f src/main/resources/db/migration/V1__create_administrative_units.sql
   ```

2. Clean database and retry:
   ```bash
   # Drop and recreate database
   docker exec -it vnmap_postgres psql -U vnmap -c "DROP DATABASE IF EXISTS vnmapdb;"
   docker exec -it vnmap_postgres psql -U vnmap -c "CREATE DATABASE vnmapdb;"
   
   # Restart application
   docker-compose restart backend
   ```

### PostGIS Extension Not Found

**Error:**
```
ERROR: could not open extension control file
```

**Solution:**

1. Ensure you're using the PostGIS image:
   ```yaml
   image: postgis/postgis:16-3.4
   ```

2. Enable extension manually:
   ```bash
   docker exec -it vnmap_postgres psql -U vnmap -d vnmapdb -c "CREATE EXTENSION IF NOT EXISTS postgis;"
   ```

---

## Redis Issues

### Redis Connection Refused

**Error:**
```
Cannot connect to Redis at localhost:6379
```

**Solution:**

1. Check Redis container:
   ```bash
   docker ps | findstr redis
   ```

2. Start Redis:
   ```bash
   docker-compose up -d redis
   ```

3. Test connection:
   ```bash
   docker exec -it vnmap_redis redis-cli -a your_password ping
   # Should return: PONG
   ```

### Redis Authentication Failed

**Error:**
```
ERR AUTH password is incorrect
```

**Solution:**

1. Update `.env` with correct password
2. Restart the backend:
   ```bash
   docker-compose restart backend
   # or if running locally:
   mvn spring-boot:run
   ```

### Redis Cache Not Working

**Symptom:**
- API calls not cached
- `cached` field always returns `false`

**Solution:**

1. Check Redis is accessible:
   ```bash
   docker exec -it vnmap_redis redis-cli -a your_password keys "*"
   ```

2. Check application logs for cache errors

---

## API Issues

### 404 Not Found

**Error:**
```json
{
  "success": false,
  "message": "No cached data available"
}
```

**Solution:**
- This is normal for the `/weather/cache` endpoint when no data is cached
- For other endpoints, verify the URL path is correct

### 400 Bad Request - Validation Error

**Error:**
```json
{
  "success": false,
  "status": 400,
  "validationErrors": {
    "lat": ["must be between -90 and 90"]
  }
}
```

**Solution:**
- Ensure latitude is between -90 and 90
- Ensure longitude is between -180 and 180

### 502 Bad Gateway - Weather API Unavailable

**Error:**
```json
{
  "success": false,
  "message": "Unable to retrieve data from external service"
}
```

**Solution:**

1. Check your OpenWeatherMap API key is valid:
   ```bash
   curl "https://api.openweathermap.org/data/2.5/weather?lat=21&lon=105&appid=YOUR_KEY"
   ```

2. Check API key has sufficient quota:
   - Free tier: 60 calls/minute
   - Paid tier: Higher limits

3. Ensure network can reach OpenWeatherMap:
   ```bash
   ping api.openweathermap.org
   ```

### Empty Response - Database Empty

**Symptom:**
```json
{
  "success": true,
  "data": []
}
```

**Solution:**
- The database schema is created but no data exists
- Follow the instructions in `SETUP_GUIDE.md` to seed the database

---

## Docker Issues

### Docker Desktop Not Running

**Error:**
```
Cannot connect to the Docker daemon
```

**Solution:**

1. Start Docker Desktop application
2. Wait for it to fully initialize (docker icon in system tray)
3. Verify:
   ```bash
   docker ps
   ```

### Port Already in Use

**Error:**
```
Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Solution:**

1. Find what's using the port:
   ```bash
   netstat -ano | findstr :8080
   # or on Linux/Mac: lsof -i :8080
   ```

2. Stop the conflicting process:
   ```bash
   taskkill /PID <PID> /F
   ```

3. Or change the port in `application.yml`:
   ```yaml
   server:
     port: 8081
   ```

### Out of Memory Error

**Error:**
```
Container killed - out of memory
```

**Solution:**

1. Increase Docker memory allocation:
   - Docker Desktop > Settings > Resources > Memory: 4GB+

2. Or reduce JVM heap in `docker-compose.yml`:
   ```yaml
   environment:
     JAVA_OPTS: -Xms128m -Xmx256m
   ```

### Docker Build Fails

**Error:**
```
error building image: cannot pull image
```

**Solution:**

1. Login to Docker Hub:
   ```bash
   docker login
   ```

2. Or use specific version tags:
   ```dockerfile
   FROM eclipse-temurin:21-jre-alpine
   ```

---

## Still Having Issues?

### Enable Debug Logging

Add to `application-dev.yml`:

```yaml
logging:
  level:
    com.vnmap: DEBUG
    org.springframework.web: DEBUG
    org.hibernate.SQL: DEBUG
```

### Check Application Logs

```bash
# If running with Docker
docker-compose logs -f backend

# If running locally
mvn spring-boot:run
```

### Reset Everything

```bash
# Stop all containers
docker-compose down -v

# Remove all volumes
docker volume prune

# Rebuild from scratch
docker-compose up -d

# Rebuild application
mvn clean package -DskipTests
```

### Get Help

1. Check the logs for specific error messages
2. Search for the error message online
3. Verify all prerequisites are installed correctly
4. Check Docker Desktop is running with sufficient resources

---

## Quick Fix Checklist

- [ ] Docker Desktop is running
- [ ] Java 21 is installed and JAVA_HOME is set
- [ ] Maven 3.9+ is installed
- [ ] `.env` file exists with correct credentials
- [ ] PostgreSQL and Redis containers are running
- [ ] No port conflicts (8080, 5432, 6379)
- [ ] OpenWeatherMap API key is valid
- [ ] Network can reach external APIs
