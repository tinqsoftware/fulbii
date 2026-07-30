-- Push verification queries (Firebase -> Laravel queue -> device)
-- Execute in the same DB used by https://fulbii.com

-- 1) Device tokens registered
SELECT id, user_id, platform, is_active, device_token, last_seen_at, created_at
FROM user_devices
ORDER BY id DESC
LIMIT 20;

-- 2) Push notifications created
SELECT id, user_id, club_id, group_pichanga_id, type, title, created_at
FROM push_notifications
ORDER BY id DESC
LIMIT 20;

-- 3) Dispatch results
SELECT id, push_notification_id, user_device_id, status, provider, error_message, sent_at, created_at
FROM push_dispatch_logs
ORDER BY id DESC
LIMIT 50;

-- 4) Summary by status/provider (last 24h)
SELECT status, provider, COUNT(*) AS total
FROM push_dispatch_logs
WHERE created_at >= NOW() - INTERVAL 24 HOUR
GROUP BY status, provider
ORDER BY status, provider;

-- 5) Queue health
SELECT queue, COUNT(*) AS total
FROM jobs
GROUP BY queue
ORDER BY queue;

SELECT COUNT(*) AS failed_total
FROM failed_jobs;
