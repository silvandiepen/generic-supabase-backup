# GitHub Actions Setup Guide

This guide walks you through setting up automated backups using GitHub Actions.

## Prerequisites

- A GitHub repository (forked from generic-supabase-backup)
- Supabase project with database credentials
- GitHub account with Actions enabled

## Step 1: Configure Your Project

Edit `config.sh` in your repository:

```bash
PROJECT_NAME="your-project-name"
BACKUP_PREFIX="${PROJECT_NAME}_backup"
RELEASE_PREFIX="backup"
DEFAULT_RETENTION_DAYS=30

# Customize backup schedules (UTC)
BACKUP_SCHEDULE_1="0 2 * * *"   # 2 AM UTC
BACKUP_SCHEDULE_2="0 14 * * *"  # 2 PM UTC
```

## Step 2: Get Supabase Credentials

### Database URLs

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Settings > Database**

#### Direct Connection URL
- Find **Connection string > URI**
- Copy the complete PostgreSQL URL
- This is your `SUPABASE_DB_URL`

#### Pooler Connection URL (Required for GitHub Actions)
- Find **Connection pooling > Connection string**
- Enable pooling if not already enabled
- Select "Session" mode
- Copy the pooler URL
- This is your `SUPABASE_SESSION_POOLER_URL`

### Storage Credentials (Optional)

For storage bucket backups:

1. Navigate to **Settings > API**
2. Copy the **URL** - this is your `SUPABASE_PROJECT_URL`
3. Copy the **service_role** key - this is your `SUPABASE_SERVICE_KEY`

## Step 3: Add GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings > Secrets and variables > Actions**
3. Click **New repository secret**
4. Add these secrets:

| Secret Name | Value | Required |
|------------|-------|----------|
| `SUPABASE_DB_URL` | Direct database connection URL | Yes |
| `SUPABASE_SESSION_POOLER_URL` | Pooler connection URL | Yes |
| `SUPABASE_PROJECT_URL` | Project URL (https://xxx.supabase.co) | No |
| `SUPABASE_SERVICE_KEY` | Service role key | No |

## Step 4: Enable GitHub Actions

1. Go to **Actions** tab in your repository
2. If prompted, enable Actions for the repository
3. You should see two workflows:
   - **Daily Backup**: Automated backups
   - **Manual Backup**: On-demand backups

## Step 5: Test Your Setup

### Manual Test

1. Go to **Actions** tab
2. Select **Manual Backup**
3. Click **Run workflow**
4. Choose options:
   - Retention days
   - Include storage (if configured)
5. Click **Run workflow**

### Verify Success

1. Check the workflow run for completion
2. Go to **Releases** to see your backup
3. Download and inspect the backup file

## Backup Storage

Backups are stored in two places:

### GitHub Releases
- Long-term storage
- Public/private based on repo visibility
- Easy to download
- Automatic cleanup based on retention

### GitHub Artifacts
- Temporary storage
- Faster access from workflows
- Compressed storage
- Auto-expires based on retention

## Scheduling

Default schedule (customizable in `config.sh`):
- 2:00 AM UTC daily
- 2:00 PM UTC daily

To customize:
1. Edit `BACKUP_SCHEDULE_1` and `BACKUP_SCHEDULE_2` in `config.sh`
2. Use [cron syntax](https://crontab.guru/)
3. Commit and push changes

## Monitoring

### Success Indicators
- ✅ Green checkmark on workflow runs
- 📦 New release created with backup file
- 📊 Backup size shown in release description

### Failure Notifications
- ❌ Failed workflow shown in Actions
- 🔔 GitHub Issue created on failure
- 📧 Email notification (if enabled in GitHub settings)

## Troubleshooting

### Common Issues

#### "Connection refused" or IPv6 errors
- Ensure `SUPABASE_SESSION_POOLER_URL` is set
- Verify pooler connection is enabled in Supabase
- Check the URL format is correct

#### "Permission denied"
- Verify database credentials are correct
- Check service role key has proper permissions
- Ensure secrets are properly set in GitHub

#### "No space left on device"
- Large databases may exceed GitHub runners limits
- Consider excluding large tables or storage buckets
- Implement incremental backups for very large databases

#### Backup not appearing in Releases
- Check workflow permissions include `contents: write`
- Verify `GITHUB_TOKEN` permissions
- Check for release creation errors in logs

### Debug Steps

1. **Check workflow logs**:
   - Go to Actions > Select failed run
   - Click on job to see detailed logs
   - Look for specific error messages

2. **Verify credentials locally**:
   ```bash
   # Test database connection
   psql "$SUPABASE_DB_URL" -c "SELECT version();"
   
   # Test pooler connection
   psql "$SUPABASE_SESSION_POOLER_URL" -c "SELECT version();"
   ```

3. **Check secret values**:
   - Ensure no extra spaces or quotes
   - Verify URLs include all parameters
   - Test with manual workflow first

## Security Best Practices

1. **Limit secret access**:
   - Use environment protection rules
   - Restrict who can run workflows
   - Review secret usage in logs

2. **Secure your backups**:
   - Keep repository private for sensitive data
   - Consider encrypting backups
   - Regularly audit access logs

3. **Rotate credentials**:
   - Update service keys periodically
   - Use separate keys for production
   - Monitor key usage in Supabase

## Advanced Configuration

### Multiple Environments

For multiple Supabase projects:

1. Create environment-specific secrets
2. Use GitHub Environments
3. Modify workflows to select environment:

```yaml
environment: production  # or staging, development
```

### Custom Notifications

Add notification steps to workflows:

```yaml
- name: Send Slack notification
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Backup failed!'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Backup Encryption

Add encryption to backup script:

```bash
# In backup-supabase.sh, after compression:
gpg --symmetric --cipher-algo AES256 "${BACKUP_NAME}.tar.gz"
```

## Getting Help

- Check [Actions logs](../../actions) for detailed error messages
- Review [GitHub Actions documentation](https://docs.github.com/en/actions)
- Open an issue in the repository
- Check Supabase connection guides