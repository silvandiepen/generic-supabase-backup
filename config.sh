#!/bin/bash
# Project Configuration
# Edit this file to customize the backup system for your project

# Project name (used in backup file names and GitHub releases)
PROJECT_NAME="my-project"

# Backup file prefix (will be used as: ${BACKUP_PREFIX}_YYYYMMDD_HHMMSS.tar.gz)
BACKUP_PREFIX="${PROJECT_NAME}_backup"

# GitHub release tag prefix (will be used as: ${RELEASE_PREFIX}-YYYY-MM-DD)
RELEASE_PREFIX="backup"

# Default retention period in days
DEFAULT_RETENTION_DAYS=30

# Backup schedules for GitHub Actions (cron format)
# Default: 2 AM and 2 PM UTC
BACKUP_SCHEDULE_1="0 2 * * *"
BACKUP_SCHEDULE_2="0 14 * * *"

# GitHub issue labels for failure notifications
FAILURE_LABEL="backup-failure"
AUTOMATED_LABEL="automated"