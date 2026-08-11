# Fulbii — Vista completa del proyecto

> Estado de producto: 10 de agosto de 2026. Para contratos y operación, revisar
> también [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Propósito

Fulbii reduce la fricción de jugar fútbol amateur: descubre una cancha, crea o
encuentra una pichanga, coordina al grupo y conserva una identidad deportiva
confiable.

## Canales y responsabilidades

| Canal | Responsabilidad |
| --- | --- |
| Flutter iOS/Android | Experiencia completa para jugadores y administradores de grupo. |
| Laravel API v1 | Fuente de verdad de permisos, datos, notificaciones y reglas. |
| Web pública | Landing, descarga y deep links; no duplica flujos de jugador. |
| Backoffice Laravel | Aprobaciones, moderación, métricas y operación. |
| watchOS/Wear OS | Sesiones, eventos y muestras de actividad compatibles. |

## Módulos funcionales

### Canchas y mapa

- Descubrimiento por mapa/lista, filtros, ubicación y clusters.
- Carga por viewport con caché en memoria y foco visual de pichangas elegidas.
- Polideportivos con canchas, fotos, superficie, formato, precio y pichangas
  abiertas futuras.
- Aportes de recintos con fotos, dirección, WhatsApp y moderación posterior.

### Grupos y comunidad

- Grupos propios y descubiertos, logo, membresía y actividad de pichangas.
- Varios administradores equivalentes; promoción, degradación y retiro sin
  dejar al grupo sin admin activo.
- Invitaciones, solicitudes, código de ingreso, preferencias de notificación
  por grupo/categoría, chat general, bloqueos y reportes.
- Cada grupo elige si todos los miembros o solo administradores crean
  pichangas.

### Pichangas, equipos y retos

- Creación desde grupo o polideportivo con cancha seleccionable, formato,
  cupos, duración, horario y audiencia.
- Agenda/lista/calendario con asistencia, anillos de estado y navegación al
  detalle.
- Equipos persistentes, formación arrastrable, solicitudes externas, cupos,
  lista de espera FIFO y avisos de cambios.
- Retos entre grupos con fotos de ambos equipos, propuestas de cancha/fecha,
  configuraciones y chat contextual.

### Perfil, actividad y rankings

- Feed y comentarios por pichanga, actividad, reportes y destacados.
- Calificación de asistentes confirmados una vez por pichanga; calificación
  semanal global entre compañeros de grupos compartidos.
- Historial de calificaciones, perfil público, clips, ranking total y bandas
  de edad de cinco años.
- La puntuación principal usa la mayor entre perfil de campo y arquero, ambos
  potenciados por físico. La fórmula exacta vive en
  `CombinedSkillRatingService`.

### Notificaciones y operación

- Bandeja, badge, deep links y push FCM para invitaciones, solicitudes,
  pichangas, retos, chats, calificaciones, aportes y lista de espera.
- Imágenes enriquecidas en iOS mediante la extensión de notificaciones; texto
  como fallback en todas las plataformas.
- Logs de envío, tokens, colas, métricas, reportes y alertas operativas en el
  backoffice y comandos Artisan.

## Reglas de datos relevantes

- `clubs` representa grupos y `club_user.estado = 1` una membresía activa.
- `polideportivo` es el recinto y `cancha` su cancha concreta; una pichanga
  usa `cancha_id` como referencia principal.
- Las modificaciones sensibles se validan en Laravel aunque la app o web
  oculten acciones no permitidas.
- Los clientes móviles son la fuente de UX de usuario; la web solo redirige a
  esa experiencia o sirve al staff autorizado.

## Lectura recomendada

1. [README](../README.md)
2. [Estado actual](AI_HANDOFF_CURRENT_STATE.md)
3. [QA móvil](QA_MOBILE_RECENT_CHANGES.md)
4. Contrato API del módulo a modificar.
5. [Operación en VPS](08_ops_runbook.md) antes de un despliegue.
