# Generic Supabase Backup

A configurable, automated backup solution for Supabase projects that can be easily forked and customized for any project. Includes database schema, data, and storage bucket backups with GitHub Actions integration.

## Features

- **Fully Configurable**: Customize project name, backup prefixes, and retention policies
- **Complete Backups**: Database schema, data, and storage buckets
- **GitHub Actions**: Automated daily backups with customizable schedules
- **GitHub Releases**: Automatic backup storage with retention management
- **IPv6 Support**: Automatic fallback to pooler connections for GitHub Actions
- **Easy Restoration**: Simple restore process with metadata tracking
- **Storage Support**: Optional storage bucket backup and restore

## Quick Start

### 1. Fork and Configure

1. Fork this repository
2. Clone your fork locally
3. Edit `config.sh` to customize your project:

```bash
# Edit config.sh
PROJECT_NAME="my-awesome-app"
BACKUP_PREFIX="${PROJECT_NAME}_backup"
RELEASE_PREFIX="backup"
DEFAULT_RETENTION_DAYS=30
```

### 2. Local Setup

```bash
# Run setup script
./scripts/setup.sh

# Edit credentials
vim scripts/.env

# Test backup
./scripts/backup-supabase.sh
```

### 3. GitHub Actions Setup

1. Go to your repository Settings > Secrets and variables > Actions
2. Add these secrets:
   - `SUPABASE_DB_URL`: Direct database connection string
   - `SUPABASE_SESSION_POOLER_URL`: Pooler connection for GitHub Actions
   - `SUPABASE_PROJECT_URL`: (Optional) For storage backups
   - `SUPABASE_SERVICE_KEY`: (Optional) For storage backups

## Configuration

### config.sh

This file contains all project-specific settings:

```bash
PROJECT_NAME="my-project"              # Your project name
BACKUP_PREFIX="${PROJECT_NAME}_backup"  # Backup file prefix
RELEASE_PREFIX="backup"                 # GitHub release tag prefix
DEFAULT_RETENTION_DAYS=30              # How long to keep backups
BACKUP_SCHEDULE_1="0 2 * * *"          # First daily backup (2 AM UTC)
BACKUP_SCHEDULE_2="0 14 * * *"         # Second daily backup (2 PM UTC)
FAILURE_LABEL="backup-failure"         # GitHub issue label for failures
AUTOMATED_LABEL="automated"            # GitHub issue label for automation
```

### scripts/.env

Your Supabase credentials (create from `.env.example`):

```bash
SUPABASE_DB_URL=postgresql://...           # Direct connection
SUPABASE_SESSION_POOLER_URL=postgresql://... # Pooler for GitHub Actions
SUPABASE_PROJECT_URL=https://...           # Optional: for storage
SUPABASE_SERVICE_KEY=eyJ...                # Optional: for storage
BACKUP_RETENTION_DAYS=30                   # Override default retention
```

## Usage

### Manual Backup
```bash
./scripts/backup-supabase.sh
```

### Restore from Backup
```bash
# List available backups
./scripts/restore-supabase.sh

# Restore specific backup
./scripts/restore-supabase.sh my-project_backup_20240101_120000.tar.gz
```

### Clean Old Backups
```bash
./scripts/cleanup-old-backups.sh
```

### Download Latest Backup from GitHub
```bash
# From current repo
./scripts/download-latest-backup.sh

# From another repo
./scripts/download-latest-backup.sh -o owner -r repo -d /tmp/backups
```

## GitHub Actions

### Automated Daily Backups

The `daily-backup.yml` workflow runs on your configured schedule and:
- Creates timestamped backups
- Uploads to GitHub Releases
- Cleans up old backups based on retention policy
- Creates issues on failure

### Manual Backup

Trigger manual backups from Actions tab with options:
- Custom retention period
- Include/exclude storage
- Tagged with trigger user

## Backup Structure

Each backup contains:
```
my-project_backup_20240101_120000/
├── schema.sql       # Database structure
├── data.sql         # Database data
├── complete.sql     # Full database dump
├── storage/         # Storage buckets (optional)
│   ├── buckets.txt
│   └── [bucket-name]/
│       └── [files...]
└── metadata.json    # Backup information
```

## Customization Guide

### For a New Project

1. **Fork this repository**
2. **Update config.sh** with your project details
3. **Customize backup schedules** in config.sh
4. **Add your Supabase credentials** to `.env` and GitHub Secrets
5. **Optional**: Modify scripts for project-specific needs

### Advanced Customization

- **Change backup format**: Modify `backup-supabase.sh`
- **Add pre/post hooks**: Add scripts before/after backup
- **Custom metadata**: Extend `metadata.json` in backup script
- **Different compression**: Change from tar.gz to your preference
- **Additional validations**: Add checks in restore script

## Troubleshooting

### IPv6 Connection Issues

GitHub Actions doesn't support IPv6. The scripts automatically use the pooler connection when `GITHUB_ACTIONS=true`. Ensure you've set `SUPABASE_SESSION_POOLER_URL`.

### Permission Errors

Ensure scripts are executable:
```bash
chmod +x scripts/*.sh
```

### Missing Dependencies

Install required tools:
- PostgreSQL client: `pg_dump`, `psql`
- `jq` for JSON processing
- `curl` for API requests

## Security

- Never commit `.env` files
- Use GitHub Secrets for sensitive data
- Regularly rotate your service keys
- Consider encrypting backups for sensitive data

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details