#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_CONFIG="$PROJECT_ROOT/config.sh"

# Load project configuration
if [ -f "$PROJECT_CONFIG" ]; then
    source "$PROJECT_CONFIG"
else
    echo "Warning: Project configuration file not found. Using defaults."
    RELEASE_PREFIX="backup"
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -o, --owner OWNER       GitHub repository owner (default: current repo)"
    echo "  -r, --repo REPO         GitHub repository name (default: current repo)"
    echo "  -d, --dest DIRECTORY    Destination directory (default: ./backups)"
    echo "  -t, --token TOKEN       GitHub token for private repos"
    echo "  -h, --help              Show this help message"
    echo
    echo "Example:"
    echo "  $0 -o myorg -r myrepo -d /tmp/backups"
}

# Parse command line arguments
OWNER=""
REPO=""
DEST_DIR="$PROJECT_ROOT/backups"
GITHUB_TOKEN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--owner)
            OWNER="$2"
            shift 2
            ;;
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -d|--dest)
            DEST_DIR="$2"
            shift 2
            ;;
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Try to get owner and repo from git remote if not provided
if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    if git remote get-url origin >/dev/null 2>&1; then
        REMOTE_URL=$(git remote get-url origin)
        if [[ $REMOTE_URL =~ github.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
            [ -z "$OWNER" ] && OWNER="${BASH_REMATCH[1]}"
            [ -z "$REPO" ] && REPO="${BASH_REMATCH[2]}"
        fi
    fi
fi

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    echo "Error: Could not determine repository owner and name."
    echo "Please specify them using -o and -r options."
    show_usage
    exit 1
fi

echo "Downloading latest backup from $OWNER/$REPO..."
echo "Destination: $DEST_DIR"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Prepare curl auth header if token provided
AUTH_HEADER=""
if [ ! -z "$GITHUB_TOKEN" ]; then
    AUTH_HEADER="-H \"Authorization: token $GITHUB_TOKEN\""
fi

# Get the latest release
echo "Fetching latest release..."
LATEST_RELEASE=$(curl -s $AUTH_HEADER \
    "https://api.github.com/repos/$OWNER/$REPO/releases" | \
    jq -r --arg prefix "$RELEASE_PREFIX" \
    '[.[] | select(.tag_name | startswith($prefix))] | first')

if [ "$LATEST_RELEASE" = "null" ] || [ -z "$LATEST_RELEASE" ]; then
    echo "Error: No backup releases found in $OWNER/$REPO"
    exit 1
fi

TAG_NAME=$(echo "$LATEST_RELEASE" | jq -r '.tag_name')
RELEASE_NAME=$(echo "$LATEST_RELEASE" | jq -r '.name')
CREATED_AT=$(echo "$LATEST_RELEASE" | jq -r '.created_at')

echo "Found release: $RELEASE_NAME (Tag: $TAG_NAME)"
echo "Created: $CREATED_AT"

# Get download URL for the backup file
ASSET_URL=$(echo "$LATEST_RELEASE" | jq -r '.assets[0].browser_download_url')
ASSET_NAME=$(echo "$LATEST_RELEASE" | jq -r '.assets[0].name')
ASSET_SIZE=$(echo "$LATEST_RELEASE" | jq -r '.assets[0].size')

if [ "$ASSET_URL" = "null" ] || [ -z "$ASSET_URL" ]; then
    echo "Error: No backup file found in the release"
    exit 1
fi

echo
echo "Backup file: $ASSET_NAME"
echo "Size: $(numfmt --to=iec-i --suffix=B $ASSET_SIZE 2>/dev/null || echo "$ASSET_SIZE bytes")"

# Download the backup
echo "Downloading..."
DEST_FILE="$DEST_DIR/$ASSET_NAME"

if [ ! -z "$GITHUB_TOKEN" ]; then
    curl -L -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/octet-stream" \
        "$ASSET_URL" -o "$DEST_FILE"
else
    curl -L "$ASSET_URL" -o "$DEST_FILE"
fi

if [ -f "$DEST_FILE" ]; then
    echo
    echo "Download complete!"
    echo "Backup saved to: $DEST_FILE"
    echo
    echo "To restore this backup, run:"
    echo "  ./scripts/restore-supabase.sh $ASSET_NAME"
else
    echo "Error: Download failed"
    exit 1
fi