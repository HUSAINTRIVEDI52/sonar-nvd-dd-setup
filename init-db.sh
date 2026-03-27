#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE sonarqube;
    CREATE DATABASE defectdojo;
    GRANT ALL PRIVILEGES ON DATABASE sonarqube TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE defectdojo TO postgres;
EOSQL
