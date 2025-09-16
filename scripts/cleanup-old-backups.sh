#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
CONFIG_FILE="$SCRIPT_DIR/.env"

# Load configuration from env file if it exists (for local runs)
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Use environment variables with defaults
PROJECT_NAME="${PROJECT_NAME:-${SUPABASE_PROJECT_NAME:-supabase-project}}"
BACKUP_PREFIX="${BACKUP_PREFIX:-${PROJECT_NAME}_backup}"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

echo "Cleaning up backups older than $RETENTION_DAYS days..."
echo "Backup directory: $BACKUP_DIR"
echo

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

OLD_BACKUPS=$(find "$BACKUP_DIR" -name "${BACKUP_PREFIX}_*.tar.gz" -type f -mtime +$RETENTION_DAYS 2>/dev/null)

if [ -z "$OLD_BACKUPS" ]; then
    echo "No backups older than $RETENTION_DAYS days found."
    exit 0
fi

echo "Found old backups to remove:"
echo "$OLD_BACKUPS" | while read -r backup; do
    if [ -f "$backup" ]; then
        echo "  - $(basename "$backup") ($(date -r "$backup" +"%Y-%m-%d %H:%M:%S"))"
    fi
done

echo
read -p "Remove these backups? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo "$OLD_BACKUPS" | while read -r backup; do
        if [ -f "$backup" ]; then
            rm -f "$backup"
            echo "Removed: $(basename "$backup")"
        fi
    done
    echo "Cleanup completed!"
else
    echo "Cleanup cancelled."
fi

echo
echo "Current backup statistics:"
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/${BACKUP_PREFIX}_*.tar.gz 2>/dev/null | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
echo "  Total backups: $BACKUP_COUNT"
echo "  Total size: $TOTAL_SIZE"

if [ $BACKUP_COUNT -gt 0 ]; then
    echo "  Oldest: $(ls -1t "$BACKUP_DIR"/${BACKUP_PREFIX}_*.tar.gz | tail -1 | xargs basename)"
    echo "  Newest: $(ls -1t "$BACKUP_DIR"/${BACKUP_PREFIX}_*.tar.gz | head -1 | xargs basename)"
fi