# API v1 - Capa social de Pichangas

> Fuente de continuidad:
> [AI_HANDOFF_CURRENT_STATE](../AI_HANDOFF_CURRENT_STATE.md).

> Contrato vigente: ratings y estrellas usan escala nativa `0.0–5.0`.

## Feed
- `GET /api/v1/pichangas/{pichanga}/feed`
- `POST /api/v1/pichangas/{pichanga}/feed/posts`
- `DELETE /api/v1/pichangas/{pichanga}/feed/posts/{post}`
- `POST /api/v1/pichangas/{pichanga}/feed/posts/{post}/comments`
- `DELETE /api/v1/pichangas/{pichanga}/feed/posts/{post}/comments/{comment}`

Rules:
- Feed posts/comments require confirmed participation and pichanga started.
- Author/admin/superadmin can remove posts/comments.

## Ratings
- `POST /api/v1/pichangas/{pichanga}/ratings`
- `GET /api/v1/pichangas/{pichanga}/ratings`

Rules:
- Only confirmed participants can rate.
- Can only rate confirmed participants of the same pichanga.
- One rating per pair `(pichanga, rater, rated)`; subsequent send updates.
- Las cinco categorías aceptan decimales de `0.0` a `5.0`.
- `Promedio jugador` promedia físico, delantero, mediocampo y defensa;
  `Como arquero` usa arquero; `Estrellas` es el mayor de ambos. No se divide
  entre dos ni se convierte desde escala 0–10.

## User card
- `GET /api/v1/users/{user}/pichanga-card?with_user_id={id}`

Returns:
- profile basics
- total played pichangas
- shared pichangas with another user
- average ratings received

## Perfil deportivo público desde grupo

- `GET /api/v1/clubs/{club}/members/{user}/public-profile`
- Disponible para grupo activo/visible o para sus miembros activos.
- Devuelve solo identidad pública, rol, estrellas, promedios, habilidades,
  pichangas y clips públicos; no devuelve correo ni datos personales privados.

## Personal activity
- `GET /api/v1/me/pichangas/history`
- `GET /api/v1/me/favorite-fields`
- `POST /api/v1/me/favorite-fields/{polideportivo}`
- `DELETE /api/v1/me/favorite-fields/{polideportivo}`
