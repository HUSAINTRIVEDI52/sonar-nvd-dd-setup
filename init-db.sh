#!/bin/bash
set -e

# Check if DATABASE exists and create if NOT
create_db_if_not_exists() {
  local db_name=$1
  if psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
    echo "Database '$db_name' already exists."
  else
    echo "Creating database '$db_name'..."
    createdb -U "$POSTGRES_USER" "$db_name"
  fi
}

create_db_if_not_exists "sonarqube"
create_db_if_not_exists "defectdojo"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE sonarqube TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE defectdojo TO postgres;
EOSQL
