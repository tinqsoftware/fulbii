# API v1 - Push and Notification Inbox

> Contrato vigente; confirmar en QA físico los flujos push y deep-link. Ver
> [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## Device registration
- `GET /api/v1/me/devices`
- `POST /api/v1/me/devices/register`
- `POST /api/v1/me/devices/{device}/deactivate`

Register body:
```json
{
  "platform": "ios",
  "device_token": "apns-or-fcm-token",
  "device_name": "iPhone 15",
  "app_version": "1.0.0"
}
```

## Notification inbox
- `GET /api/v1/me/notifications`
- `POST /api/v1/me/notifications/read-all`
- `POST /api/v1/me/notifications/{notification}/read`

## Trigger points
- Pichanga creation sends initial notification batch.
- Re-notify send creates push records and dispatch logs.

## Delivery driver
- `PUSH_DRIVER=log` (default): logs sends.
- `PUSH_DRIVER=fcm`: sends to Firebase Cloud Messaging HTTP v1 using service account.
  Required env:
  - `FCM_PROJECT_ID`
  - `FCM_SERVICE_ACCOUNT_PATH`
  Optional defaults:
  - `FCM_SCOPE=https://www.googleapis.com/auth/firebase.messaging`
  - `FCM_TOKEN_URI=https://oauth2.googleapis.com/token`
