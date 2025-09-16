# Generic Supabase Backup

Automated backup solution for Supabase projects. Just add your credentials as GitHub Secrets and it starts working automatically with daily backups.

## Features

- 🚀 **Zero Configuration**: Just add secrets and it works
- 📅 **Automatic Daily Backups**: Runs at 2 AM and 2 PM UTC
- 💾 **Complete Backups**: Database schema, data, and storage buckets
- 📦 **GitHub Releases**: Automatic backup storage with retention
- 🌐 **IPv6 Support**: Automatic fallback to pooler connections
- 🔄 **Easy Restoration**: Simple restore process

## Quick Start - GitHub Actions Only

1. **Use this template** to create your repository
2. **Add GitHub Secrets** (Settings > Secrets > Actions):
   - `SUPABASE_DB_URL` - Your database URL (required)
   - `SUPABASE_SESSION_POOLER_URL` - Pooler URL for GitHub Actions (required)
   - `SUPABASE_PROJECT_URL` - For storage backups (optional)
   - `SUPABASE_SERVICE_KEY` - For storage backups (optional)

3. **That's it!** Daily backups will run automatically at 2 AM and 2 PM UTC

### Optional Secrets for Customization

- `PROJECT_NAME` - Custom project name (default: "supabase")
- `BACKUP_RETENTION_DAYS` - Days to keep backups (default: 30)
- `RELEASE_PREFIX` - GitHub release prefix (default: "backup")

## Getting Your Supabase Credentials

### Required: Database URLs

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Settings > Database**

**Direct Connection URL** (`SUPABASE_DB_URL`):
- Find **Connection string > URI**
- Copy the complete PostgreSQL URL

**Pooler Connection URL** (`SUPABASE_SESSION_POOLER_URL`):
- Find **Connection pooling > Connection string**
- Enable pooling if not already enabled
- Select "Session" mode
- Copy the pooler URL

### Optional: Storage Credentials

For storage bucket backups:
1. Navigate to **Settings > API**
2. Copy the **URL** for `SUPABASE_PROJECT_URL`
3. Copy the **service_role** key for `SUPABASE_SERVICE_KEY`

## Manual Backup

1. Go to **Actions** tab
2. Select **Manual Backup**
3. Click **Run workflow**

## Downloading Backups

Backups are stored as GitHub Releases. To download:
1. Go to **Releases** section
2. Download the `.tar.gz` file

## Local Usage (Optional)

If you want to run backups locally:

```bash
# Clone your repo
git clone your-repo
cd your-repo

# Setup
./scripts/setup.sh

# Copy and edit credentials
cp scripts/.env.example scripts/.env
# Edit scripts/.env with your credentials

# Run backup
./scripts/backup-supabase.sh

# Restore backup
./scripts/restore-supabase.sh backup_file.tar.gz
```

## Backup Contents

Each backup contains:
```
project_backup_20240101_120000/
├── schema.sql       # Database structure
├── data.sql         # Database data
├── complete.sql     # Full database dump
├── storage/         # Storage buckets (optional)
└── metadata.json    # Backup information
```

## Troubleshooting

### IPv6 Connection Issues
GitHub Actions requires the pooler connection. Make sure `SUPABASE_SESSION_POOLER_URL` is set correctly.

### Backup Failures
- Check Actions tab for error logs
- Verify all required secrets are set
- Ensure database credentials are correct

### No Backups Appearing
- Check if Actions are enabled for your repository
- Verify the workflow has run (Actions tab)
- Check Releases section

## Security

- All credentials are stored as GitHub Secrets
- Never commit `.env` files
- Backups inherit your repository's visibility (public/private)

## License

MIT License - see LICENSE file