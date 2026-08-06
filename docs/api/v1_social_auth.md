# API v1 - Social Auth

> Contrato vigente. No registrar secretos, client IDs privados ni tokens en
> documentación. Ver [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## Endpoints
### POST `/api/v1/auth/social/login`
Public endpoint.

Body:
```json
{
  "provider": "google",
  "id_token": "....",
  "provider_uid": "optional-in-trusted-mode",
  "email": "optional-in-trusted-mode",
  "name": "optional",
  "avatar_url": "optional",
  "device_name": "iphone-alfredo"
}
```

Response:
```json
{
  "token_type": "Bearer",
  "access_token": "...",
  "needs_onboarding": true,
  "user": { "...": "..." },
  "auth_mode": "trusted_mode"
}
```

### POST `/api/v1/auth/logout`
Requires `auth:sanctum` bearer token.

## Modes
- `SOCIAL_AUTH_TRUSTED_MODE=true`:
  backend trusts `provider_uid/email` from app (for local/dev).
- `SOCIAL_AUTH_TRUSTED_MODE=false`:
  backend validates provider token.
  - Google: validated via tokeninfo endpoint.
  - Apple: JWT payload checks (issuer/audience) are applied.
