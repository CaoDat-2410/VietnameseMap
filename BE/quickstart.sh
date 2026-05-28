#!/bin/bash
# Vietnam Map Backend - Quick Start Script for Linux/Mac
# =====================================================

set -e

echo "============================================"
echo "  Vietnam Map Backend - Quick Setup"
echo "============================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}[ERROR] Java 21 not found. Please install JDK 21.${NC}"
    echo "Download: https://adoptium.net/"
    exit 1
fi
JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 21 ]; then
    echo -e "${RED}[ERROR] Java 21+ required. Found Java $JAVA_VERSION${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Java $JAVA_VERSION is installed${NC}"

# Check for Maven
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}[ERROR] Maven not found. Please install Maven 3.9+${NC}"
    echo "Download: https://maven.apache.org/download.cgi"
    exit 1
fi
echo -e "${GREEN}[OK] Maven is installed${NC}"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[ERROR] Docker not found. Please install Docker Desktop.${NC}"
    echo "Download: https://www.docker.com/products/docker-desktop/"
    exit 1
fi
echo -e "${GREEN}[OK] Docker is installed${NC}"

echo ""
echo "============================================"
echo "  Step 1: Setup Environment File"
echo "============================================"
if [ ! -f ".env" ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo -e "${GREEN}[OK] .env created${NC}"
    echo ""
    echo -e "${YELLOW}[IMPORTANT] Please edit .env and add your credentials:${NC}"
    echo "  - DB_PASSWORD"
    echo "  - REDIS_PASSWORD"
    echo "  - OWM_API_KEY"
    echo ""
else
    echo -e "${GREEN}[OK] .env already exists${NC}"
fi

echo ""
echo "============================================"
echo "  Step 2: Start Docker Services"
echo "============================================"
echo "Starting PostgreSQL and Redis..."
docker-compose up -d postgres redis
echo -e "${GREEN}[OK] Docker services started${NC}"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 10

echo ""
echo "============================================"
echo "  Step 3: Build the Project"
echo "============================================"
echo "Building..."
mvn clean package -DskipTests -q
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Build failed${NC}"
    echo "Try running: mvn clean package -DskipTests"
    exit 1
fi
echo -e "${GREEN}[OK] Build successful${NC}"

echo ""
echo "============================================"
echo "  Step 4: Start the Application"
echo "============================================"
echo -e "${GREEN}Starting Spring Boot application...${NC}"
echo ""
echo "API will be available at: http://localhost:8080"
echo "Swagger UI: http://localhost:8080/swagger-ui.html"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the application
java -jar target/vn-map-backend-1.0.0.jar
