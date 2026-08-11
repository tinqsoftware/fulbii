# API v1 — Feed, calificaciones y rankings

## Feed de pichanga

- `GET /api/v1/pichangas/{pichanga}/feed`
- `POST /api/v1/pichangas/{pichanga}/feed/posts`
- `DELETE /api/v1/pichangas/{pichanga}/feed/posts/{post}`
- `POST /api/v1/pichangas/{pichanga}/feed/posts/{post}/comments`
- `DELETE /api/v1/pichangas/{pichanga}/feed/posts/{post}/comments/{comment}`

Publicar/comentar requiere participación confirmada y pichanga iniciada. El
autor, admin o superadmin puede retirar contenido permitido; cualquier usuario
autenticado puede reportar mediante `POST /api/v1/reports` con contexto.

## Calificaciones de pichanga

- `GET|POST /api/v1/pichangas/{pichanga}/ratings`

Calificador y calificado deben estar confirmados en la misma pichanga, no puede
existir autocalificación y solo se permite un voto por `(pichanga, calificador,
calificado)`. Un intento repetido se rechaza; no es una edición.

## Calificación entre compañeros y perfiles

- `GET /api/v1/users/{user}/ratings/eligibility`
- `POST /api/v1/users/{user}/ratings`
- `GET /api/v1/users/{user}/ratings/history`
- `GET /api/v1/users/{user}/player-ranking`
- `GET /api/v1/rankings`

La calificación de perfil exige un grupo activo compartido, excluye al propio
usuario y permite una por semana ISO global para el mismo par, aunque compartan
varios grupos.

## Fórmula única

Cada habilidad se agrega por separado sobre votos válidos. Después:

```text
campo = promedio(delantero, mediocampo, defensa)
jugador = promedio(campo, físico)
arquero = promedio(arquero, físico)
principal = mayor(jugador, arquero)
```

En empate gana jugador de campo; la posición de campo empata en Delantero →
Mediocampo → Defensa. `player_average`, `goalkeeper_average`, `stars` y
`primary_role`/`primary_position` son derivados de
`CombinedSkillRatingService`. Equipos, grupos, destacados y rankings consumen
el mismo resultado. Usuarios sin votos se ordenan al final del ranking.

## Otros recursos sociales

- `GET /api/v1/users/{user}/pichanga-card?with_user_id={id}`
- `GET|POST|DELETE /api/v1/me/favorite-fields/...`
- `GET|POST|DELETE|PUT /api/v1/me/profile-clips/...`

El perfil contextual de grupo no expone datos personales privados.
