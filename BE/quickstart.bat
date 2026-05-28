@echo off
REM Vietnam Map Backend - Quick Start Script for Windows
REM =====================================================

echo ============================================
echo   Vietnam Map Backend - Quick Setup
echo ============================================
echo.

REM Check for Java
java -version 2>&1 | findstr "version" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Java 21 not found. Please install JDK 21.
    echo Download: https://adoptium.net/
    pause
    exit /b 1
)
echo [OK] Java is installed

REM Check for Maven
mvn -version 2>&1 | findstr "Apache Maven" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Maven not found. Please install Maven 3.9+
    echo Download: https://maven.apache.org/download.cgi
    pause
    exit /b 1
)
echo [OK] Maven is installed

REM Check for Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker not found. Please install Docker Desktop.
    echo Download: https://www.docker.com/products/docker-desktop/
    pause
    exit /b 1
)
echo [OK] Docker is installed

echo.
echo ============================================
echo   Step 1: Setup Environment File
echo ============================================
if not exist ".env" (
    echo Creating .env from .env.example...
    copy .env.example .env
    echo [OK] .env created
    echo.
    echo [IMPORTANT] Please edit .env and add your credentials:
    echo   - DB_PASSWORD
    echo   - REDIS_PASSWORD
    echo   - OWM_API_KEY
    echo.
) else (
    echo [OK] .env already exists
)

echo.
echo ============================================
echo   Step 2: Start Docker Services
echo ============================================
echo Starting PostgreSQL and Redis...
docker-compose up -d postgres redis
if %errorlevel% neq 0 (
    echo [ERROR] Failed to start Docker services
    pause
    exit /b 1
)
echo [OK] Docker services started

REM Wait for PostgreSQL to be ready
echo Waiting for PostgreSQL to be ready...
timeout /t 10 /nobreak >nul

echo.
echo ============================================
echo   Step 3: Build the Project
echo ============================================
echo Building...
call mvn clean package -DskipTests -q
if %errorlevel% neq 0 (
    echo [ERROR] Build failed
    echo Try running: mvn clean package -DskipTests
    pause
    exit /b 1
)
echo [OK] Build successful

echo.
echo ============================================
echo   Step 4: Start the Application
echo ============================================
echo Starting Spring Boot application...
echo.
echo API will be available at: http://localhost:8080
echo Swagger UI: http://localhost:8080/swagger-ui.html
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the application
java -jar target\vn-map-backend-1.0.0.jar
