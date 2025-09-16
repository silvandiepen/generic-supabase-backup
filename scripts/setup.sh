#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Supabase Backup Setup"
echo "===================="
echo

if ! command -v pg_dump &> /dev/null; then
    echo "Error: PostgreSQL client tools (pg_dump) not found!"
    echo
    echo "Please install PostgreSQL client tools:"
    echo "  - macOS: brew install postgresql"
    echo "  - Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "  - CentOS/RHEL: sudo yum install postgresql"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq not found!"
    echo
    echo "Please install jq:"
    echo "  - macOS: brew install jq"
    echo "  - Ubuntu/Debian: sudo apt-get install jq"
    echo "  - CentOS/RHEL: sudo yum install jq"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "Error: curl not found!"
    echo "Please install curl."
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "Creating .env file from template..."
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    echo
    echo "IMPORTANT: Please edit $SCRIPT_DIR/.env with your Supabase credentials!"
    echo
    echo "You can find your credentials in:"
    echo "1. Supabase Dashboard > Settings > Database"
    echo "2. Supabase Dashboard > Settings > API (for service role key)"
    echo
else
    echo ".env file already exists."
fi

chmod +x "$SCRIPT_DIR/backup-supabase.sh"
chmod +x "$SCRIPT_DIR/restore-supabase.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/cleanup-old-backups.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/download-latest-backup.sh" 2>/dev/null || true

echo
echo "Setup complete!"
echo
echo "Next steps:"
echo "1. Edit $SCRIPT_DIR/.env with your Supabase credentials"
echo "2. Run: $SCRIPT_DIR/backup-supabase.sh"
echo
echo "To schedule automatic backups, add to crontab:"
echo "0 2 * * * $SCRIPT_DIR/backup-supabase.sh"