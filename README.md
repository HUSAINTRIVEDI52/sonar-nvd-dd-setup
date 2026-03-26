# CI/CD Pipeline for SonarQube & DefectDojo on GCP

This repository contains a CI/CD pipeline to deploy and manage SonarQube and DefectDojo on a GCP Compute Engine instance.

## Architecture

- **Deployment**: Docker Compose
- **Platform**: Google Cloud Platform (GCP)
- **CI/CD**: GitHub Actions
- **Authentication**: GCP Service Account (SA) Key

## Setup Instructions

### 1. GCP Service Account setup

1.  Go to the [GCP Console](https://console.cloud.google.com/).
2.  Navigate to **IAM & Admin > Service Accounts**.
3.  Create a new service account (e.g., `cicd-deployer`).
4.  Assign the following roles:
    - `Compute Instance Admin (v1)`
    - `Service Account User`
    - `IAP-secured Tunnel User` (If you want to use IAP for SSH)
5.  Create a JSON Key for this service account and download it.

### 2. GitHub Secrets setup

Add the following secrets to your GitHub repository (**Settings > Secrets and variables > Actions**):

- `GCP_SA_KEY`: Paste the content of the JSON Key file.
- `GCP_PROJECT_ID`: Your GCP Project ID.
- `GCP_VM_NAME`: The name of your Compute Engine VM.
- `GCP_ZONE`: The zone of your VM (e.g., `us-central1-a`).
- `NVD_API_KEY`: Your NVD API Key.
- `SONAR_DB_PASSWORD`: Password for SonarQube database.
- `DB_PASSWORD`: Master password for PostgreSQL.
- `DOJO_DB_PASSWORD`: Password for DefectDojo database.
- `DD_SECRET_KEY`: A random secret key for DefectDojo.

### 3. VM Preparation

Ensure your GCP VM has enough resources (at least 4GB RAM recommended for SonarQube and DefectDojo combined). The `deploy.sh` script will automatically install Docker and Docker Compose.

### 4. Deployment

Push your changes to the `main` branch to trigger the deployment pipeline.

```bash
git add .
git commit -m "Initial setup"
git push origin main
```

## Services Access

After deployment, the services will be available at:

- **SonarQube**: `http://<VM_IP>:9000`
- **DefectDojo**: `http://<VM_IP>:8080`

> [!NOTE]
> Ensure that the GCP Firewall allows traffic on ports 9000 and 8080.
