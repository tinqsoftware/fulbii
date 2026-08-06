# Fulbii — Estado actual y relevo para IA

> Fuente de verdad operativa al **5 de agosto de 2026**. Antes de modificar
> funcionalidades, revisar este documento y los contratos en `docs/api/`.
> Los documentos marcados como históricos preservan contexto, pero no definen
> el comportamiento vigente.

## Arquitectura y puntos de entrada

- **Backend:** Laravel, rutas en `routes/api.php`, controladores API v1 en
  `app/Http/Controllers/Api/V1`.
- **App móvil:** Flutter/Riverpod en `fulbii_app/lib/src`; el cliente HTTP y
  repositorios constituyen el contrato consumido por las pantallas.
- **Recintos:** `polideportivo` es el recinto y `cancha` su cancha concreta.
  En una pichanga, `cancha_id` es el vínculo canónico; `field_id` se conserva
  por compatibilidad.
- **Wearables:** watchOS y Wear OS son companions; el contrato de sesiones
  está en `docs/api/v1_watch_match_sessions.md`.

## Decisiones funcionales vigentes

### Grupos

- `clubs` es el grupo y `club_user.estado = 1` es la **única** membresía
  activa. `created_by` solo identifica al creador, no lo convierte en miembro.
- `GET /clubs?scope=mine` devuelve membresías activas aunque el grupo sea
  privado o esté desactivado. `scope=discover` devuelve solo grupos activos,
  visibles y sin membresía activa; funciona para invitados.
- Crear/editar grupo permite nombre obligatorio, descripción y `logo`
  opcionales. Un grupo invisible no permite solicitudes por búsqueda o enlace.
- El detalle de grupo ofrece agenda pública cuando corresponde, integrantes,
  administración para miembros y preferencias de notificación personales.

### Estrellas y perfil deportivo público

- Las cinco habilidades (`físico`, `arquero`, `delantero`, `mediocampo`,
  `defensa`) usan decimales nativos de **0.0 a 5.0**.
- `Promedio jugador` = media de físico, delantero, mediocampo y defensa.
  `Como arquero` = habilidad arquero. `Estrellas` = el mayor de ambos, con
  prioridad para promedio jugador en empate.
- No existe conversión desde 0–10 ni división entre dos. Las estrellas son
  globales del jugador; el grupo solo es contexto de acceso.
- `GET /clubs/{club}/members/{user}/public-profile` nunca expone correo,
  fecha de nacimiento u otros atributos privados. Los clips públicos se leen
  desde `GET /users/{user}/profile-clips`.

### Pichangas

- `GET /pichangas/my-board` alimenta la agenda inicial y
  `GET /pichangas/calendar?month=YYYY-MM` carga historial/agenda por mes.
- El detalle devuelve recinto (`court_name`, `field_name`, `address`,
  `venue_photo_url`, `venue_field_id`), fase (`upcoming`, `in_progress`,
  `finished`), estado legible, capacidad, cupos, equipos y permisos de acción.
- El hero del detalle usa primero foto de cancha, luego polideportivo. Tocar
  el recinto abre su detalle Flutter y volver retorna a la pichanga.
- Los equipos son persistentes: cada participante `confirmed` requiere
  `team_code` y `team_slot`. La confirmación directa respeta el equipo elegido;
  una solicitud externa aceptada se asigna al equipo menos cargado.
- La pichanga permite baja mientras siga en fase `upcoming`; al retirar se
  liberan equipo y slot. No hay CTA de confirmación cuando está iniciada,
  terminada, cancelada o llena.

## Mantenimiento y datos

- Tras un despliegue con datos históricos, ejecutar con respaldo previo:

  ```bash
  php artisan pichangas:repair-team-assignments --force
  ```

  El comando es idempotente; repara únicamente confirmaciones sin equipo o
  slot, distribuyéndolas equilibradamente y guardando el resultado.
- En el entorno local se ejecutó el 5 de agosto de 2026 y reparó **15**
  participaciones históricas.
- El reset de calificaciones es deliberado y separado:

  ```bash
  php artisan ratings:reset --force
  ```

  Elimina calificaciones e historial; no ejecutarlo sin autorización explícita.

## Validación reciente

- Backend: `php artisan test tests/Feature/Api/PichangasAvailableWidgetTest.php`
  pasó con 9 pruebas y 96 assertions.
- Flutter: `flutter test test/pichangas_screen_test.dart
  test/club_detail_view_state_test.dart` pasó.
- `flutter analyze` no tiene errores nuevos; mantiene avisos informativos
  preexistentes en pantallas de canchas/mapa.

## Riesgos y siguientes pasos

1. Hacer QA manual iPhone del detalle de pichanga: notch, tabs fijas, volver,
   CTA de cambio/baja y navegación al polideportivo.
2. Ejecutar la reparación de equipos en staging/producción solo después de
   respaldar la base y verificar el contador resultante por pichanga.
3. Completar QA físico de push y sincronización Watch → backend → iPhone.
4. Mantener las APIs y esta guía sincronizadas si cambian los contratos.

## Documentos canónicos

- [Índice del proyecto](../README.md)
- [Contratos de clubes](api/v1_clubs_and_invitations.md)
- [Contratos de pichangas](api/v1_pichangas.md)
- [Contratos de canchas](api/v1_fields.md)
- [Contratos social/rating](api/v1_pichanga_social.md)
- [Operación](08_ops_runbook.md)
- [Estado y brechas](STATUS_GAPS.md)
