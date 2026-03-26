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

# Run Docker Compose
echo "Stopping existing services if any..."
sudo docker compose down --remove-orphans || true

echo "Starting services (this may take a few minutes)..."
sudo docker compose up -d

echo "----------------------------------------------"
echo "SonarQube: http://$(curl -s ifconfig.me):9000"
echo "DefectDojo: http://$(curl -s ifconfig.me):8080"
echo "----------------------------------------------"