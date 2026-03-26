#!/bin/bash

# Update and install dependencies
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Install Docker using the official convenience script
if ! command -v docker &> /dev/null
then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
fi

# Navigate to project directory
mkdir -p ~/setup-pipeline
cd ~/setup-pipeline

# Ensure .env is set up (This assumes environment variables are passed through SSH or generated)
# The GitHub Action will handle copying the .env file

# Run Docker Compose
echo "Stopping existing services if any..."
sudo docker compose down --remove-orphans || true

echo "Starting services..."
sudo docker compose up -d

echo "SonarQube and DefectDojo deployed successfully!"
