# Security hardening rollout

## Required production configuration

Use the production environment template as the baseline, then verify these
values before deploy. Do not send the `.env` file or any secret to chat.

- `APP_ENV=production`, `APP_DEBUG=false`, `SESSION_SECURE_COOKIE=true`.
- `SOCIAL_AUTH_TRUSTED_MODE=false`, `APPLE_AUTH_REQUIRE_NONCE=true` and the
  optional `APPLE_AUTH_AUDIENCES` only when more than one native client ID is
  genuinely used.
- `SANCTUM_EXPIRATION_MINUTES=43200` and `SANCTUM_MAX_TOKENS_PER_USER=5` (or a
  documented stricter product decision).
- `WATCH_RETENTION_DAYS=30`; the scheduler must be active so
  `watch:purge-retained` runs every night.
- Install `ffmpeg` and `ffprobe` on every PHP worker, set their absolute
  paths in `MEDIA_FFMPEG_BINARY` / `MEDIA_FFPROBE_BINARY`, and confirm a
  profile clip is transcoded before allowing media uploads. Images are decoded
  and re-encoded as JPEG; clips are transcoded to a seven-second MP4 before
  becoming public.
- `CORS_ALLOWED_ORIGINS=https://fulbii.com`; add an origin only after it is
  reviewed and owned by Fulbii.

Deploy the new `deploy/nginx/fulbii.com.conf`, test it with `nginx -t`, reload
Nginx, and verify the real response includes HSTS, CSP, `nosniff`,
`Referrer-Policy`, `Permissions-Policy`, and secure cookies. The supplied TLS
paths are the standard Let's Encrypt paths; adapt them only if the issuer uses
another location.

## Identity and device changes

Apple Sign In now requires a nonce. Release the updated Flutter application
before forcing the backend change; old app builds will correctly receive `422`
from Apple login. Clear existing mobile sessions after a suspected compromise
through `POST /api/v1/auth/logout-all`.

Enable MFA in the identity layer used for `/admin` accounts. Laravel roles
remain authorization controls, not a second authentication factor.

## Operations and privacy

- Restrict VPS SSH to named administrators, disable password authentication,
  keep firewall ports to 80/443/SSH-via-VPN, and keep FCM credentials outside
  the release directory with mode `640`.
- Encrypt backups, test restoration quarterly, and limit access to database,
  object storage, Firebase, Apple, Google, DNS and GitHub accounts.
- Treat watch location, HealthKit data, media, push tokens and logs as
  sensitive. Document consent, account deletion handling, retention periods
  and the incident contact path.
- Review failed logins, 401/403/429/5xx spikes, admin events, queue failures,
  storage growth and backup success at least weekly.

## Release verification

```bash
composer audit --locked --no-interaction
npm audit --omit=dev --audit-level=high
php artisan test --stop-on-failure
php artisan schedule:list
curl -I https://fulbii.com
```

Do not consider the release complete until the external header check and an
Apple sign-in test on a physical release build have passed.
