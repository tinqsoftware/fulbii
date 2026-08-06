# API v1 - Clubs and Invitations

> Contrato vigente al 5 de agosto de 2026. Fuente de continuidad:
> [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

## Authentication
`GET /api/v1/clubs` permite descubrimiento sin sesión. Cuando recibe un token
Sanctum válido, usa esa identidad para separar las listas personales. Los demás
endpoints que leen datos privados o realizan mutaciones requieren `auth:sanctum`.

## Clubs
### GET `/api/v1/clubs?scope=mine|discover&q=...`
- Con sesión, `scope=mine` devuelve exclusivamente grupos con membresía activa (`club_user.estado = 1`), incluso si son privados o están desactivados.
- Con sesión, `scope=discover` devuelve grupos activos (`clubs.estado = 1`), visibles y sin membresía activa del usuario.
- Sin sesión, `scope=discover` devuelve el mismo conjunto activo y visible; `scope=mine` devuelve `items: []`.
- Cada item incluye `is_member`, `is_owner`, `is_mine`, `my_role` e `is_active`. `is_owner` es solo informativo; `is_mine` equivale a una membresía activa. Las dos listas son excluyentes para un usuario autenticado.

### POST `/api/v1/clubs`
Creates group and auto-adds creator as `admin`.

Accepts JSON when no image is selected, or `multipart/form-data` with an
optional `logo` image (maximum 2 MB).

Body:
```json
{
  "nombre": "Fulbii Sur",
  "descripcion": "Grupo de pichangas",
  "is_visible": true,
  "pichanga_create_scope": "admins",
  "renotify_scope": "members",
  "renotify_cooldown_minutes": 30,
  "renotify_max_per_pichanga": 5,
  "audience_max_degree": 3
}
```

### GET `/api/v1/clubs/{club}`
Returns group details and caller membership role.

### PUT `/api/v1/clubs/{club}`
Admin or superadmin only.

Las mutaciones sobre un grupo desactivado responden `409` con
`code: "club_inactive"`. Los miembros activos aún pueden consultar el detalle,
pero no crear pichangas, enviar invitaciones, gestionar solicitudes o retos.

### Join links and requests
### GET `/api/v1/clubs/join/{joinCode}`
Preview de grupo por link (incluye estado del usuario).

### POST `/api/v1/clubs/join/{joinCode}/request`
Solicitar ingreso usando link para un grupo activo, visible y con solicitudes habilitadas.

### POST `/api/v1/clubs/{club}/join-requests`
Solicitar ingreso por búsqueda visible.

### GET `/api/v1/clubs/{club}/join-requests`
Cola de solicitudes para admin/superadmin.

### POST `/api/v1/clubs/{club}/join-requests/{joinRequest}/decision`
Decisión admin: `accept|reject`.

### POST `/api/v1/clubs/{club}/join-requests/{joinRequest}/cancel`
Cancelar solicitud pendiente (solo solicitante).

### POST `/api/v1/clubs/{club}/join-code/rotate`
Rota el `join_code` y retorna `join_url` nuevo.

### GET `/api/v1/clubs/{club}/members`
Visible to group members and superadmin.

Cada integrante activo incluye rol y estrellas globales 0.0–5.0. Al tocarlo,
la app usa el perfil público contextual:

### GET `/api/v1/clubs/{club}/members/{user}/public-profile`
Autenticación opcional. Permite acceso si el grupo está activo y visible, o si
el solicitante es miembro activo/superadmin. El usuario consultado debe ser
miembro activo. No incluye datos privados.

### PUT `/api/v1/clubs/{club}/members/{user}/role`
Admin or superadmin only.
Body:
```json
{
  "rol": "admin"
}
```

### DELETE `/api/v1/clubs/{club}/members/{user}`
Admin or superadmin only.
Cannot remove the last admin.

## Invitations
### GET `/api/v1/invitations`
Current user pending invitations.

### POST `/api/v1/clubs/{club}/invitations`
Admin or superadmin only. Invite by `nick` or `email`.

Body examples:
```json
{ "nick": "pichanguero21" }
```
```json
{ "email": "jugador@example.com" }
```

### POST `/api/v1/invitations/{invitation}/respond`
Invited user accepts/rejects.

Body:
```json
{
  "action": "accept"
}
```

### POST `/api/v1/invitations/{invitation}/revoke`
Admin or superadmin only, pending invitations only.
