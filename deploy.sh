#!/bin/bash
set -e

# Update and install dependencies
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Install Docker if not present
if ! command -v docker &> /dev/null
then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
fi

# Navigate to project directory
cd ~/setup-pipeline

# Configure host machine required settings for SonarQube Elasticsearch
echo "Configuring kernel parameters for SonarQube..."
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.d/99-sonarqube.conf > /dev/null

# Step 1: Start only the Database and Redis
echo "Starting Database and Redis..."
sudo docker compose up -d db redis

# Step 2: Wait for Database to be Healthy
echo "Waiting for Database to become ready..."
until [ "`sudo docker inspect -f {{.State.Health.Status}} devsecops-db`"=="healthy" ]; do
    sleep 2
done

# Step 3: Force Database Creation (Separate schemas for Sonar/Dojo)
echo "Ensuring sonarqube and defectdojo databases exist..."
sudo docker exec devsecops-db bash /docker-entrypoint-initdb.d/init-db.sh

# Step 4: Start everything else
echo "Starting SonarQube and DefectDojo..."
sudo docker compose up -d

# Step 5: Force DefectDojo Database Migrations (Sometimes skipped on first boot)
echo "Running DefectDojo Database Migrations..."
sudo docker exec defectdojo python3 manage.py migrate --noinput
sudo docker exec defectdojo python3 manage.py create_groups
sudo docker exec defectdojo python3 manage.py loaddata initializer.json

# Step 6: Restart to ensure clean state
echo "Finalizing startup..."
sudo docker restart defectdojo defectdojo-worker

echo "----------------------------------------------"
echo "Deployment successful! Services are initializing."
echo "SonarQube: http://$(curl -s ifconfig.me):9000 (Takes ~2-3 mins)"
echo "DefectDojo: http://$(curl -s ifconfig.me):8080"
echo "----------------------------------------------"