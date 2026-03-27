#!/bin/bash
set -e

echo "=================================================="
echo "DevSecOps Pipeline Deployment Script"
echo "=================================================="

# Update and install dependencies
echo "Step 1: Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Install Docker if not present
if ! command -v docker &> /dev/null
then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out and back in for group changes to take effect."
fi

# Check if docker compose is available
if ! docker compose version &> /dev/null
then
    echo "ERROR: docker compose is not available. Please ensure Docker Compose V2 is installed."
    exit 1
fi

# Navigate to project directory
cd ~/setup-pipeline || { echo "ERROR: Directory ~/setup-pipeline not found"; exit 1; }

# Configure host machine required settings for SonarQube Elasticsearch
echo "Step 2: Configuring kernel parameters for SonarQube..."
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.d/99-sonarqube.conf > /dev/null
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.d/99-sonarqube.conf > /dev/null

# Set proper ulimits
ulimit -n 65536 || true
ulimit -u 4096 || true

# Load .env file if it exists
if [ -f .env ]; then
    echo "Step 3: Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
else
    echo "WARNING: .env file not found. Make sure environment variables are set."
fi

# Validate required environment variables
REQUIRED_VARS=("DB_PASSWORD" "DD_SECRET_KEY")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Required environment variable $var is not set"
        exit 1
    fi
done

# Clean up any existing containers
echo "Step 4: Cleaning up existing containers..."
sudo docker compose down -v || true

# Start the database first
echo "Step 5: Starting PostgreSQL database..."
sudo docker compose up -d db

# Wait for database to be healthy
echo "Step 6: Waiting for database to be ready..."
attempt=0
max_attempts=30
until [ "$(sudo docker inspect -f '{{.State.Health.Status}}' devsecops-db 2>/dev/null)" == "healthy" ]; do
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo "ERROR: Database failed to become healthy after $max_attempts attempts"
        sudo docker logs devsecops-db
        exit 1
    fi
    echo "Waiting for database... (attempt $attempt/$max_attempts)"
    sleep 2
done
echo "Database is healthy!"

# Verify databases were created
echo "Step 7: Verifying databases were created..."
sleep 3
sudo docker exec devsecops-db psql -U postgres -c "\l" | grep -E "sonarqube|defectdojo" || {
    echo "ERROR: Required databases were not created. Check init-db.sh"
    exit 1
}
echo "Databases verified!"

# Start Redis
echo "Step 8: Starting Redis..."
sudo docker compose up -d redis

# Wait for Redis to be healthy
echo "Waiting for Redis to be ready..."
attempt=0
until [ "$(sudo docker inspect -f '{{.State.Health.Status}}' devsecops-redis 2>/dev/null)" == "healthy" ]; do
    attempt=$((attempt + 1))
    if [ $attempt -eq 30 ]; then
        echo "ERROR: Redis failed to become healthy"
        sudo docker logs devsecops-redis
        exit 1
    fi
    echo "Waiting for Redis... (attempt $attempt/30)"
    sleep 1
done
echo "Redis is healthy!"

# Initialize DefectDojo
echo "Step 9: Initializing DefectDojo..."
sudo docker compose up defectdojo-initializer

# Check if initializer completed successfully
if [ $? -ne 0 ]; then
    echo "ERROR: DefectDojo initialization failed!"
    sudo docker logs defectdojo-initializer
    exit 1
fi
echo "DefectDojo initialization completed!"

# Start all remaining services
echo "Step 10: Starting all services..."
sudo docker compose up -d

# Wait for services to be running
echo "Step 11: Waiting for services to start..."
sleep 10

# Check service health
echo "Step 12: Checking service status..."
sudo docker compose ps

# Get external IP
EXTERNAL_IP=$(curl -s ifconfig.me || echo "localhost")

echo "=================================================="
echo "✅ Deployment Complete!"
echo "=================================================="
echo ""
echo "🔧 Service URLs:"
echo "   SonarQube:   http://${EXTERNAL_IP}:9000"
echo "   DefectDojo:  http://${EXTERNAL_IP}:8080"
echo ""
echo "📝 Default Credentials:"
echo "   SonarQube:   admin / admin (change on first login)"
echo "   DefectDojo:  admin / admin (change on first login)"
echo ""
echo "⏱️  Services may take 2-3 minutes to fully initialize"
echo ""
echo "📊 To view logs:"
echo "   SonarQube:     sudo docker logs -f sonarqube"
echo "   DefectDojo:    sudo docker logs -f defectdojo"
echo "   All services:  sudo docker compose logs -f"
echo ""
echo "🔄 To restart services:"
echo "   sudo docker compose restart"
echo ""
echo "🛑 To stop services:"
echo "   sudo docker compose down"
echo ""
echo "=================================================="