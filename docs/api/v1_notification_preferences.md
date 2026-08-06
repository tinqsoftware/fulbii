# API v1 - Group Notification Preferences

> Contrato vigente. La preferencia es personal por miembro activo; no concede
> permisos de administración. Ver [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## Authentication
All endpoints require `auth:sanctum`.

## Endpoints
### GET `/api/v1/clubs/{club}/notification-preference`
Returns the current user's preference for the given club.

Response example:
```json
{
  "club_id": 2,
  "mode": "mute_24h",
  "muted_until": "2026-03-20T15:42:11.000000Z",
  "is_muted_now": true,
  "updated_at": "2026-03-19T15:42:11.000000Z"
}
```

If no preference exists yet:
```json
{
  "club_id": 2,
  "mode": "always_on",
  "muted_until": null,
  "is_muted_now": false
}
```

### PUT `/api/v1/clubs/{club}/notification-preference`
Body:
```json
{
  "mode": "mute_1w"
}
```

Allowed values:
- `always_on`
- `mute_24h`
- `mute_1w`
- `mute_forever`

Rules:
- Only members of the club (or superadmin) can read/update preference.
- Mute applies only to push notifications.
- No critical-notification bypass when muted.
