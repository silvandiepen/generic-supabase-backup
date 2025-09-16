#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
CONFIG_FILE="$SCRIPT_DIR/.env"
PROJECT_CONFIG="$PROJECT_ROOT/config.sh"

# Load project configuration
if [ -f "$PROJECT_CONFIG" ]; then
    source "$PROJECT_CONFIG"
else
    echo "Warning: Project configuration file not found. Using defaults."
    PROJECT_NAME="supabase-project"
    BACKUP_PREFIX="${PROJECT_NAME}_backup"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found!"
    echo "Please create the .env file with your Supabase credentials."
    exit 1
fi

source "$CONFIG_FILE"

# Check if we're in GitHub Actions and need to use pooler connection
if [ "${GITHUB_ACTIONS:-false}" = "true" ] && [ ! -z "${SUPABASE_SESSION_POOLER_URL:-}" ]; then
    echo "Running in GitHub Actions - using pooler connection for IPv4 compatibility"
    DB_URL="$SUPABASE_SESSION_POOLER_URL"
    echo "Using pooler URL: ${DB_URL%%:*}://***@${DB_URL#*@}"
else
    DB_URL="$SUPABASE_DB_URL"
    echo "Using direct connection URL: ${DB_URL%%:*}://***@${DB_URL#*@}"
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="${BACKUP_PREFIX}_${TIMESTAMP}"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

mkdir -p "$BACKUP_PATH"

echo "Starting $PROJECT_NAME backup..."
echo "Backup directory: $BACKUP_PATH"

echo "1. Backing up database schema..."
pg_dump "$DB_URL" \
    --schema-only \
    --no-owner \
    --no-privileges \
    -f "$BACKUP_PATH/schema.sql"

echo "2. Backing up database data..."
pg_dump "$DB_URL" \
    --data-only \
    --disable-triggers \
    -f "$BACKUP_PATH/data.sql"

echo "3. Creating complete backup..."
pg_dump "$DB_URL" \
    --no-owner \
    --no-privileges \
    -f "$BACKUP_PATH/complete.sql"

echo "4. Backing up storage buckets..."
if [ ! -z "${SUPABASE_SERVICE_KEY:-}" ] && [ ! -z "${SUPABASE_PROJECT_URL:-}" ]; then
    mkdir -p "$BACKUP_PATH/storage"
    
    echo "   Fetching bucket list..."
    curl -s -H "apikey: $SUPABASE_SERVICE_KEY" \
         -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
         "$SUPABASE_PROJECT_URL/storage/v1/bucket" | \
         jq -r '.[].name' > "$BACKUP_PATH/storage/buckets.txt"
    
    if [ -f "$BACKUP_PATH/storage/buckets.txt" ]; then
        while IFS= read -r bucket; do
            echo "   Backing up bucket: $bucket"
            mkdir -p "$BACKUP_PATH/storage/$bucket"
            
            curl -s -H "apikey: $SUPABASE_SERVICE_KEY" \
                 -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
                 "$SUPABASE_PROJECT_URL/storage/v1/object/list/$bucket" | \
                 jq -r '.[] | @base64' | while read -r obj; do
                     name=$(echo "$obj" | base64 -d | jq -r '.name')
                     if [ ! -z "$name" ]; then
                         echo "      Downloading: $name"
                         curl -s -H "apikey: $SUPABASE_SERVICE_KEY" \
                              -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
                              "$SUPABASE_PROJECT_URL/storage/v1/object/$bucket/$name" \
                              -o "$BACKUP_PATH/storage/$bucket/$name"
                     fi
                 done
        done < "$BACKUP_PATH/storage/buckets.txt"
    fi
else
    echo "   Skipping storage backup (SUPABASE_SERVICE_KEY or SUPABASE_PROJECT_URL not set)"
fi

echo "5. Creating backup metadata..."
cat > "$BACKUP_PATH/metadata.json" << EOF
{
  "project_name": "$PROJECT_NAME",
  "timestamp": "$TIMESTAMP",
  "date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "supabase_project_url": "${SUPABASE_PROJECT_URL:-not_set}",
  "backup_version": "1.0"
}
EOF

echo "6. Compressing backup..."
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

echo "Backup completed successfully!"
echo "Backup saved to: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"

BACKUP_SIZE=$(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)
echo "Backup size: $BACKUP_SIZE"