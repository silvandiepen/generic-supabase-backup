# GitHub Setup - Quick Guide

## Step 1: Add Secrets

Go to your repository **Settings > Secrets and variables > Actions** and add:

### Required Secrets

| Secret | Where to Find It |
|--------|-----------------|
| `SUPABASE_DB_URL` | Supabase Dashboard > Settings > Database > Connection string > **URI** |
| `SUPABASE_SESSION_POOLER_URL` | Supabase Dashboard > Settings > Database > Connection pooling > **Connection string** |

### Optional Secrets

| Secret | Where to Find It | Purpose |
|--------|-----------------|---------|
| `SUPABASE_PROJECT_URL` | Supabase Dashboard > Settings > General > **URL** | Storage backups |
| `SUPABASE_SERVICE_KEY` | Supabase Dashboard > Settings > API > **service_role** | Storage backups |
| `PROJECT_NAME` | Your choice (e.g., "my-app") | Custom backup names |
| `BACKUP_RETENTION_DAYS` | Number (default: 30) | Days to keep backups |

## Step 2: Enable Actions

1. Go to **Actions** tab
2. Enable workflows if prompted
3. That's it! Backups run automatically at 2 AM and 2 PM UTC

## Step 3: Test

1. Go to **Actions** > **Manual Backup**
2. Click **Run workflow**
3. Check **Releases** for your backup

## Important Notes

### Pooler Connection Required
GitHub Actions needs the pooler connection (`SUPABASE_SESSION_POOLER_URL`) for IPv4 support:
1. Go to Database settings
2. Enable **Connection pooling**
3. Select **Session** mode
4. Copy the pooler connection string

### Backup Storage
- Backups are stored as GitHub Releases
- They're automatically cleaned up based on retention days
- Download from the Releases page

### Troubleshooting
If backups fail:
1. Check the Actions logs for errors
2. Verify pooler connection is enabled
3. Ensure secrets have no extra spaces