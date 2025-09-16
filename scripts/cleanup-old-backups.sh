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
    DEFAULT_RETENTION_DAYS=30
fi

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-$DEFAULT_RETENTION_DAYS}

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