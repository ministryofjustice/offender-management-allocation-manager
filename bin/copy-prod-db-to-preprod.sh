#! /bin/bash

# Copy MOIC prod database to preprod

# Based on steps documented here:
# https://docs.google.com/document/d/15rP3GFcHFivTvYPlrWqgjwW_R5rM2Emw4e-lYhaAB1U/edit

# Dependencies:
# kubectl must be installed and authenticated to MOJ Cloud Platform
# yq must be installed – brew install yq
command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl not found. Please install and configure it for MOJ Cloud Platform."; exit 1; }
command -v yq >/dev/null 2>&1 || { echo >&2 "yq not found. Please install with: brew install yq"; exit 1; }

# Explain what this script will do and ask for confirmation to continue
echo "This script will copy the MOIC production database into pre-production."
echo "All data currently in pre-production will be destroyed."
echo "Production data will not be changed."
echo
read -rp "Continue? (y/n) " CONT

if [ "$CONT" = "y" ]; then
  echo "Continuing...";
else
  echo "Exiting";
  exit
fi

# Name of the Kubernetes Secret which holds RDS credentials
# Same for both production and preproduction
DB_SECRET_NAME="allocation-rds-instance-output"

PROD_KUBE_NAMESPACE="offender-management-production"
PREPROD_KUBE_NAMESPACE="offender-management-preprod"

# Helper to read keys from the base64-encoded YAML Kubernetes Secrets
function read_secret_field() {
  echo "$1" | yq r - "data.$2" | base64 --decode
}

# Source: Production
# Get database credentials from the Kubenetes Secret
PROD_SECRET=$(kubectl get secret $DB_SECRET_NAME -o yaml -n $PROD_KUBE_NAMESPACE)
SOURCE_DB=$(read_secret_field "$PROD_SECRET" "postgres_name")
SOURCE_PASS=$(read_secret_field "$PROD_SECRET" "postgres_password")
SOURCE_USER=$(read_secret_field "$PROD_SECRET" "postgres_user")
SOURCE_HOST=$(read_secret_field "$PROD_SECRET" "postgres_host")

# Target: Pre-production
# Get database credentials from the Kubenetes Secret
PREPROD_SECRET=$(kubectl get secret $DB_SECRET_NAME -o yaml -n $PREPROD_KUBE_NAMESPACE)
TARGET_DB=$(read_secret_field "$PREPROD_SECRET" "postgres_name")
TARGET_PASS=$(read_secret_field "$PREPROD_SECRET" "postgres_password")
TARGET_USER=$(read_secret_field "$PREPROD_SECRET" "postgres_user")
TARGET_HOST=$(read_secret_field "$PREPROD_SECRET" "postgres_host")

# Build an array of environment variables to pass into the pod
POD_ENV=( --env="ALLOW_EMPTY_PASSWORD=yes" )
POD_ENV+=( --env="SOURCE_DB=$SOURCE_DB" )
POD_ENV+=( --env="SOURCE_PASS=$SOURCE_PASS" )
POD_ENV+=( --env="SOURCE_USER=$SOURCE_USER" )
POD_ENV+=( --env="SOURCE_HOST=$SOURCE_HOST" )
POD_ENV+=( --env="TARGET_DB=$TARGET_DB" )
POD_ENV+=( --env="TARGET_PASS=$TARGET_PASS" )
POD_ENV+=( --env="TARGET_USER=$TARGET_USER" )
POD_ENV+=( --env="TARGET_HOST=$TARGET_HOST" )

PG_POD_NAME="pgclient-prod"

# Spin up a Postgres CLI container to perform the migration with
kubectl run $PG_POD_NAME --restart=Never --image=bitnami/postgresql "${POD_ENV[@]}" -n $PREPROD_KUBE_NAMESPACE

# Wait for it to come up
kubectl wait --for=condition=Ready pods/$PG_POD_NAME -n $PREPROD_KUBE_NAMESPACE

echo 'Running'

# Copy migration script to the remote container
LOCAL_TEMP_FILE=$(mktemp)
cat > "$LOCAL_TEMP_FILE" <<- 'EOM'
echo "Migrating database"
echo "---"
echo "Source host: $SOURCE_HOST"
echo "Target host: $TARGET_HOST"
echo "---"

echo "Terminate connections to preprod database"
PGPASSWORD=$TARGET_PASS psql -h $TARGET_HOST -U $TARGET_USER $TARGET_DB -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$TARGET_DB' AND pid <> pg_backend_pid();"

echo "---"

echo "Drop target DB"
PGPASSWORD=$TARGET_PASS dropdb -h $TARGET_HOST -U $TARGET_USER $TARGET_DB

echo "---"

echo "Create new target DB"
PGPASSWORD=$TARGET_PASS createdb -E utf-8 -O $TARGET_USER -h $TARGET_HOST -U $TARGET_USER $TARGET_DB

echo "---"

echo "Steps to copy across the prod DB"
PGPASSWORD=$SOURCE_PASS pg_dump -U $SOURCE_USER -h $SOURCE_HOST -d $SOURCE_DB -O --section=pre-data | sed -e s/$SOURCE_USER/$TARGET_USER/g | PGPASSWORD=$TARGET_PASS psql -U $TARGET_USER -h $TARGET_HOST -d $TARGET_DB
PGPASSWORD=$SOURCE_PASS pg_dump -U $SOURCE_USER -h $SOURCE_HOST -d $SOURCE_DB -t '*_seq' | PGPASSWORD=$TARGET_PASS psql -U $TARGET_USER -h $TARGET_HOST -d $TARGET_DB
PGPASSWORD=$SOURCE_PASS pg_dump -U $SOURCE_USER -h $SOURCE_HOST -d $SOURCE_DB -O --section=data | PGPASSWORD=$TARGET_PASS psql -U $TARGET_USER -h $TARGET_HOST -d $TARGET_DB
PGPASSWORD=$SOURCE_PASS pg_dump -U $SOURCE_USER -h $SOURCE_HOST -d $SOURCE_DB -O --section=post-data | PGPASSWORD=$TARGET_PASS psql -U $TARGET_USER -h $TARGET_HOST -d $TARGET_DB

echo "---"
echo "Migration complete - check above for unexpected errors"
EOM
kubectl cp "$LOCAL_TEMP_FILE" $PREPROD_KUBE_NAMESPACE/$PG_POD_NAME:/tmp/migrate_db.sh
rm "$LOCAL_TEMP_FILE"

# Execute migration script on container
echo '--- Executing migration script ---'
kubectl exec $PG_POD_NAME -n $PREPROD_KUBE_NAMESPACE -- bash /tmp/migrate_db.sh
echo '--- End migration script ---'

# Kill the pod
kubectl delete pod --now $PG_POD_NAME -n $PREPROD_KUBE_NAMESPACE

echo 'Finished'
