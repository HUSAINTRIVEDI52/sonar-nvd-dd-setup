#!/bin/bash
set -e

echo "=================================================="
echo "DevSecOps Pipeline Deployment Script"
echo "=================================================="

# Step 1: Install system dependencies
echo "Step 1: Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release

# Step 2: Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Step 2: Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker $USER
else
    echo "Step 2: Docker already installed, skipping."
fi

# Check docker compose
if ! docker compose version &> /dev/null; then
    echo "ERROR: docker compose is not available."
    exit 1
fi

# Navigate to project directory
cd ~/setup-pipeline || { echo "ERROR: Directory ~/setup-pipeline not found"; exit 1; }

# Step 3: Configure kernel parameters for SonarQube
echo "Step 3: Configuring kernel parameters for SonarQube..."
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-sonarqube.conf > /dev/null
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.d/99-sonarqube.conf > /dev/null
ulimit -n 65536 || true

# Step 4: Load environment variables
if [ -f .env ]; then
    echo "Step 4: Loading environment variables..."
    set -a
    source .env
    set +a
else
    echo "WARNING: .env file not found."
fi

# Validate required variables
for var in DB_PASSWORD DD_SECRET_KEY; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Required environment variable $var is not set"
        exit 1
    fi
done

# Step 5: Clean up existing containers and volumes for fresh start
echo "Step 5: Cleaning up existing containers..."
sudo docker compose down -v --remove-orphans || true

# Step 6: Start PostgreSQL first
echo "Step 6: Starting PostgreSQL database..."
sudo docker compose up -d db

# Step 7: Wait for database to be healthy
echo "Step 7: Waiting for database to be ready..."
attempt=0
max_attempts=30
until [ "$(sudo docker inspect -f '{{.State.Health.Status}}' devsecops-db 2>/dev/null)" = "healthy" ]; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "ERROR: Database failed to become healthy"
        sudo docker logs devsecops-db --tail 20
        exit 1
    fi
    echo "  Waiting... ($attempt/$max_attempts)"
    sleep 3
done
echo "Database is healthy!"

# Step 8: Create required databases
echo "Step 8: Creating SonarQube and DefectDojo databases..."
sudo docker exec devsecops-db bash /docker-entrypoint-initdb.d/init-db.sh

# Step 9: Start Redis
echo "Step 9: Starting Redis..."
sudo docker compose up -d redis

attempt=0
until [ "$(sudo docker inspect -f '{{.State.Health.Status}}' devsecops-redis 2>/dev/null)" = "healthy" ]; do
    attempt=$((attempt + 1))
    if [ $attempt -ge 20 ]; then
        echo "ERROR: Redis failed to become healthy"
        exit 1
    fi
    sleep 2
done
echo "Redis is healthy!"

# Step 10: Run DefectDojo initializer (migrations, admin user, fixtures)
echo "Step 10: Running DefectDojo initializer..."
sudo docker compose up defectdojo-initializer
echo "DefectDojo initialization complete!"

# Step 11: Start all remaining services
echo "Step 11: Starting all services..."
sudo docker compose up -d

# Step 12: Show status
echo "Step 12: Checking service status..."
sleep 10
sudo docker compose ps

EXTERNAL_IP=$(curl -s ifconfig.me || echo "YOUR_VM_IP")

echo "=================================================="
echo "Deployment Complete!"
echo "=================================================="
echo "SonarQube:   http://${EXTERNAL_IP}:9000  (default: admin/admin)"
echo "DefectDojo:  http://${EXTERNAL_IP}:8080  (default: admin/admin)"
echo "Note: Services may take 2-3 minutes to fully initialize."
echo "=================================================="