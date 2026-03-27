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

# Run Docker Compose
echo "Applying configurations (Docker Compose will skip unchanged services)..."
sudo docker compose up -d

echo "----------------------------------------------"
echo "SonarQube: http://$(curl -s ifconfig.me):9000"
echo "DefectDojo: http://$(curl -s ifconfig.me):8080"
echo "----------------------------------------------"