#!/bin/bash

# Update and install dependencies
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Install Docker
if ! command -v docker &> /dev/null
then
    echo "Installing Docker..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

# Install Docker Compose (if not included in plugin)
if ! command -v docker-compose &> /dev/null
then
    echo "Installing Docker Compose standalone..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
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
