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
    BACKUP_PREFIX="*_backup"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found!"
    echo "Please create the .env file with your Supabase credentials."
    exit 1
fi

source "$CONFIG_FILE"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup-file.tar.gz>"
    echo
    echo "Available backups:"
    ls -1t "$BACKUP_DIR"/${BACKUP_PREFIX}_*.tar.gz 2>/dev/null || echo "No backups found in $BACKUP_DIR"
    exit 1
fi

BACKUP_FILE="$1"

if [[ ! "$BACKUP_FILE" =~ ^/ ]]; then
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "WARNING: This will restore the database from backup!"
echo "Backup file: $BACKUP_FILE"
echo "Target database: $SUPABASE_DB_URL"
echo
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "1. Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

BACKUP_NAME=$(basename "$BACKUP_FILE" .tar.gz)
RESTORE_DIR="$TEMP_DIR/$BACKUP_NAME"

if [ ! -d "$RESTORE_DIR" ]; then
    echo "Error: Invalid backup structure"
    exit 1
fi

echo "2. Reading backup metadata..."
if [ -f "$RESTORE_DIR/metadata.json" ]; then
    cat "$RESTORE_DIR/metadata.json"
    echo
fi

echo "3. Restoring database..."
echo "   WARNING: This will drop and recreate all tables!"
read -p "   Continue with database restore? (yes/no): " db_confirm

if [ "$db_confirm" = "yes" ]; then
    if [ -f "$RESTORE_DIR/complete.sql" ]; then
        echo "   Restoring from complete backup..."
        psql "$SUPABASE_DB_URL" -f "$RESTORE_DIR/complete.sql"
    else
        if [ -f "$RESTORE_DIR/schema.sql" ]; then
            echo "   Restoring schema..."
            psql "$SUPABASE_DB_URL" -f "$RESTORE_DIR/schema.sql"
        fi
        
        if [ -f "$RESTORE_DIR/data.sql" ]; then
            echo "   Restoring data..."
            psql "$SUPABASE_DB_URL" -f "$RESTORE_DIR/data.sql"
        fi
    fi
    echo "   Database restore completed!"
else
    echo "   Skipping database restore."
fi

echo "4. Checking for storage backup..."
if [ -d "$RESTORE_DIR/storage" ] && [ ! -z "${SUPABASE_SERVICE_KEY:-}" ] && [ ! -z "${SUPABASE_PROJECT_URL:-}" ]; then
    echo "   Storage backup found!"
    echo "   WARNING: Storage restore must be done manually."
    echo "   Storage files are available in: $RESTORE_DIR/storage"
    echo
    echo "   To restore storage files:"
    echo "   1. Review the files in the storage directory"
    echo "   2. Upload them using Supabase Dashboard or API"
    echo
    read -p "   Copy storage files to a permanent location? (yes/no): " storage_confirm
    
    if [ "$storage_confirm" = "yes" ]; then
        STORAGE_RESTORE_DIR="$PROJECT_ROOT/restored_storage_$(date +%Y%m%d_%H%M%S)"
        cp -r "$RESTORE_DIR/storage" "$STORAGE_RESTORE_DIR"
        echo "   Storage files copied to: $STORAGE_RESTORE_DIR"
    fi
else
    echo "   No storage backup found or API credentials not set."
fi

echo
echo "Restore process completed!"
echo
echo "IMPORTANT:"
echo "- Review your application to ensure everything is working correctly"
echo "- Some Supabase features (like RLS policies) may need manual verification"
echo "- Storage files need to be manually uploaded if restored"