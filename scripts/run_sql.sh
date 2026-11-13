#!/usr/bin/env bash
set -euo pipefail
until docker exec relational_db_optimization_postgres pg_isready -U app_user -d operations_db >/dev/null 2>&1; do sleep 1; done
echo 'Database is ready. Initialization scripts run automatically on first container startup.'
docker exec -it relational_db_optimization_postgres psql -U app_user -d operations_db
