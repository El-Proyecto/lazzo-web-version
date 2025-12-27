# Scheduled Notifications - Quick Reference

## 🚀 Quick Deploy Checklist

### 1. Database (Supabase Dashboard → SQL Editor)
```sql
-- Copy and run: supabase/migrations/20251226_scheduled_notifications_optimization.sql
-- Then verify: supabase/migrations/20251226_test_scheduled_notifications.sql
```

### 2. Edge Functions Secret (Dashboard → Edge Functions → Secrets)
```bash
SCHEDULER_SECRET=<generate-random-32-chars>

# Generate:
# Linux/Mac: openssl rand -base64 32
# PowerShell: -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})
```

### 3. Deploy Edge Functions
```bash
supabase functions deploy notify-events-ending --no-verify-jwt
supabase functions deploy notify-uploads-closing --no-verify-jwt
```

### 4. Test Manually
```bash
# Should fail (401)
curl https://yourproject.supabase.co/functions/v1/notify-events-ending

# Should work
curl -X POST https://yourproject.supabase.co/functions/v1/notify-events-ending \
  -H "x-scheduler-secret: YOUR_SECRET_HERE"
```

---

## 📊 What Was Fixed

| Issue | Before | After |
|-------|--------|-------|
| **Duplicates** | Race conditions possible | Atomic UNIQUE constraint |
| **Performance** | N+1 nested loops | Single JOIN query |
| **Indexing** | Non-sargable expression | Indexed computed column |
| **Time accuracy** | Hardcoded "15 min" | Dynamic calculation |
| **Security** | Open to public | Secret header required |

---

## 🔍 Monitoring Commands

```sql
-- Check recent notifications
SELECT type, COUNT(*), COUNT(DISTINCT recipient_user_id) 
FROM notifications 
WHERE created_at > NOW() - INTERVAL '1 hour'
  AND type IN ('eventEndsSoon', 'uploadsClosing')
GROUP BY type;

-- Find duplicates (should be 0)
SELECT recipient_user_id, event_id, type, COUNT(*) 
FROM notifications 
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY 1,2,3 HAVING COUNT(*) > 1;
```

```bash
# Edge Function logs
supabase functions logs notify-events-ending --limit 20
```

---

## 📅 Scheduler Setup

**Cron-job.org (recommended for simplicity):**
- Events Ending: `*/5 * * * *` (every 5 min)
- Uploads Closing: `*/10 * * * *` (every 10 min)
- Add header: `x-scheduler-secret: YOUR_SECRET`

**GitHub Actions (`.github/workflows/scheduled-notifications.yml`):**
```yaml
name: Scheduled Notifications
on:
  schedule:
    - cron: '*/5 * * * *'  # Events ending
    - cron: '*/10 * * * *' # Uploads closing

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Events Ending
        if: github.event.schedule == '*/5 * * * *'
        run: |
          curl -X POST ${{ secrets.SUPABASE_URL }}/functions/v1/notify-events-ending \
            -H "x-scheduler-secret: ${{ secrets.SCHEDULER_SECRET }}"
      
      - name: Trigger Uploads Closing
        if: github.event.schedule == '*/10 * * * *'
        run: |
          curl -X POST ${{ secrets.SUPABASE_URL }}/functions/v1/notify-uploads-closing \
            -H "x-scheduler-secret: ${{ secrets.SCHEDULER_SECRET }}"
```

---

## 🛠️ Troubleshooting

**401 Unauthorized:**
- Check secret matches in Dashboard → Secrets
- Verify header name: `x-scheduler-secret` (not `authorization`)

**Slow queries:**
```sql
REINDEX INDEX idx_events_living_end_datetime;
REINDEX INDEX idx_events_recap_uploads_closing;
```

**Duplicates appearing:**
```sql
-- Verify unique constraint exists
SELECT indexname FROM pg_indexes 
WHERE indexname = 'idx_notifications_dedup_unique';
```

---

## 📖 Full Documentation

See [SCHEDULED_NOTIFICATIONS_OPTIMIZATION.md](./SCHEDULED_NOTIFICATIONS_OPTIMIZATION.md) for complete details.
