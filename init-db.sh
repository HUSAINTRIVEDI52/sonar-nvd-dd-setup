#!/bin/bash
set -e

echo "Initializing databases for SonarQube and DefectDojo..."

# Function to create database if it doesn't exist
create_db_if_not_exists() {
  local db_name=$1
  
  # Check if database exists
  if psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
    echo "✓ Database '$db_name' already exists."
  else
    echo "→ Creating database '$db_name'..."
    createdb -U "$POSTGRES_USER" "$db_name"
    echo "✓ Database '$db_name' created successfully."
  fi
}

# Create databases
create_db_if_not_exists "sonarqube"
create_db_if_not_exists "defectdojo"

# Grant privileges
echo "→ Granting privileges..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    -- Grant all privileges on databases
    GRANT ALL PRIVILEGES ON DATABASE sonarqube TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE defectdojo TO postgres;
    
    -- Set default privileges for DefectDojo database
    \c defectdojo
    GRANT ALL ON SCHEMA public TO postgres;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
    
    -- Set default privileges for SonarQube database
    \c sonarqube
    GRANT ALL ON SCHEMA public TO postgres;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
EOSQL

echo "✓ Database initialization completed successfully!"
echo "  - sonarqube: Ready for SonarQube"
echo "  - defectdojo: Ready for DefectDojo"