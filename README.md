# Fulbii

Fulbii es una plataforma mobile-first para encontrar canchas, organizar
pichangas, coordinar grupos, competir en retos y construir un perfil futbolero.
La app Flutter es el producto para jugadores; Laravel ofrece la API, enlaces
compartibles y el backoffice de operación y moderación.

## Productos

- **App Flutter:** canchas, pichangas, grupos, retos, perfiles, rankings,
  notificaciones, aportes de recintos y comunidad.
- **Web pública:** landing, descarga y enlaces profundos de grupo, pichanga e
  invitación. No replica flujos de jugador para no duplicar permisos o reglas.
- **Backoffice web:** reportes, moderación, aportes de canchas, strikes,
  métricas y salud operativa.
- **Watch:** companions watchOS/Wear OS para actividad y sesiones compatibles.

## Cómo está organizado

| Área | Ubicación |
| --- | --- |
| API y backoffice Laravel | `app/`, `routes/api.php`, `routes/web.php` |
| App móvil Flutter | `fulbii_app/` |
| watchOS | `fulbii_watchos/` |
| Wear OS | `fulbii_wearos/` |
| Contratos, operación y QA | `docs/` |

## Documentación canónica

- [Estado actual y relevo](docs/AI_HANDOFF_CURRENT_STATE.md)
- [Vista completa del proyecto](docs/PROJECT_OVERVIEW.md)
- [QA móvil de cambios recientes](docs/QA_MOBILE_RECENT_CHANGES.md)
- [Contenido para landing](docs/PRODUCT_LANDING_CONTENT.md)
- [Operación en VPS](docs/08_ops_runbook.md)
- [Checklist de release](docs/06_release_e2e_checklist.md)
- [Verificación de push](docs/09_firebase_push_verification_step_by_step.md)
- [Brechas y próximos pasos](docs/STATUS_GAPS.md)

## Contratos API

- [Grupos, miembros e invitaciones](docs/api/v1_clubs_and_invitations.md)
- [Canchas y aportes](docs/api/v1_fields.md)
- [Pichangas, equipos y lista de espera](docs/api/v1_pichangas.md)
- [Feed, calificaciones y rankings](docs/api/v1_pichanga_social.md)
- [Notificaciones push y bandeja](docs/api/v1_push_and_notifications.md)
- [Moderación, reportes y bloqueos](docs/api/v1_moderation.md)
- [Preferencias de notificaciones](docs/api/v1_notification_preferences.md)

## Reglas operativas importantes

- No subas `firebase-service-account.json`, tokens, `.env` ni `seed_error.log`.
- En el VPS no ejecutes `php artisan migrate --force` globalmente mientras el
  historial heredado de la tabla `migrations` siga incompleto. Ejecuta solo las
  migraciones nuevas por `--path`, verifica el estado y normaliza el baseline
  antes de usar el comando global.
- Push requiere `PUSH_DRIVER=fcm`, una cuenta de servicio legible por
  `www-data` y el worker systemd `fulbii-queue` activo en las colas
  `push,default`.

Los documentos históricos conservan contexto, pero no reemplazan los enlaces
canónicos anteriores.
