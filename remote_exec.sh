#!/bin/bash
set -e
echo "=== Starting remote deployment ==="
mkdir -p ~/setup-pipeline
tar -xzvf ~/deploy.tar.gz -C ~/setup-pipeline/
chmod +x ~/setup-pipeline/deploy.sh
chmod +x ~/setup-pipeline/init-db.sh
cd ~/setup-pipeline/
./deploy.sh
rm -f ~/deploy.tar.gz
echo "=== Deployment successful! ==="
