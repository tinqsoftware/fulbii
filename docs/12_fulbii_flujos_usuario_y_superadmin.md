# Fulbii — MD Maestro de Flujos (App Usuario + Web Superadmin)

> **Histórico / de referencia.** Los flujos de grupos, detalle de pichanga y
> ratings evolucionaron. Validar decisiones actuales en
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md).

## Estado y alcance del documento
- Fecha de corte: 2026-04-01.
- Alcance: **solo funcionalidades implementadas** y trazables a código/rutas actuales.
- Cobertura:
  - App Flutter: todos los procesos de usuario final.
  - Web: solo backoffice `superadmin` / `staff_admin`.
- Fuentes de verdad usadas:
  - API: `/routes/api.php`
  - Web: `/routes/web.php`
  - Flutter: `/fulbii_app/lib/src/features/*`
  - Backoffice: `/app/Http/Controllers/Admin/BackofficeController.php` + `/resources/views/admin/*`

---

## Addendum 2026-04-06 — Fulbii Watch MVP

### Flujo usuario reloj (watchOS/Wear OS)
1. `PreMatchView`: muestra partido actual/mock, centro deportivo y cancha, CTA `Iniciar partido`.
2. `LiveMatchView`: timer, distancia, estado GPS, botones grandes `Gol`, `Asistencia`, `Pausa/Reanudar`, `Finalizar`.
3. Registro eventos con minuto automático: `max(1, floor((now-startTime)/60)+1)`.
4. Pausa/Reanuda captura GPS.
5. Auto-fin por inactividad de movimiento de 30 minutos.
6. `MatchSummaryView`: minutos jugados, distancia, goles y mini ruta.
7. `SettingsDebugView`: toggles debug y `Simular partido de 10 min`.

### Sync MVP
- Apple: `WatchConnectivity` stub + cola local.
- Android: `SyncManager` stub (preparado para Data Layer).
- Backend expone:
  - `POST /api/v1/watch/match-sessions`
  - `POST /api/v1/watch/match-sessions/{id}/samples/batch`
  - `POST /api/v1/watch/match-sessions/{id}/events/batch`
  - `POST /api/v1/watch/match-sessions/{id}/finish`

### Datos nuevos backend
- `watch_match_sessions`
- `watch_position_samples`
- `watch_match_events`
- `field_geometries`
- `group_pichangas.cancha_id` para vínculo canónico de pichanga con cancha.

---

## Mapa de navegación app
### Navegación principal (tab bar)
1. `Mapa` → canchas, filtros, bottom sheet de cancha, solicitud de nueva cancha.
2. `Grupos` → mis grupos, descubrir, invitaciones, crear grupo, entrar por link.
3. `Pichangas` → listado de pichangas disponibles.
4. `Inbox` → notificaciones y deep-link al destino.
5. `Perfil` → datos de usuario, clips, favoritos, historial, logout.

### Navegación global
- `AppBar` de `MainShell` tiene campana con badge rojo de no leídas.
- La campana abre la pestaña `Inbox` y refresca contador.
- Push/deep-link puede abrir:
  - detalle de pichanga,
  - detalle/chat de reto,
  - pantalla de compartir pichanga desde widget.

---

## Inventario UI por tipo

## Pantallas (Screen)
- `LoginScreen` (Google/Apple)
- `OnboardingScreen` (nick + sexo)
- `MapScreen`
- `ClubsScreen`
- `JoinClubByLinkScreen`
- `ClubDetailScreen`
- `ChallengesScreen`
- `ChallengeDetailScreen`
- `PichangasScreen`
- `CreatePichangaScreen`
- `PichangaDetailScreen`
- `InboxScreen`
- `ProfileScreen`
- `PichangaWidgetShareScreen`
- `PichangaDetailScreen` (abierta por push/inbox/deep-link)

## Popup / Dialog (`AlertDialog`)
- Crear grupo.
- Invitar usuario por nick/email.
- Retar grupo.
- Renotify preview/send.
- Crear post en feed.
- Agregar comentario.
- Calificar jugadores.
- Proponer/decidir opciones de reto (cancha/horario/configuración).
- Editar perfil.
- Selección de tramo de 7s para clip.
- Solicitar nueva cancha.

## Bottom sheet
- Detalle de cancha al tocar marcador en mapa.

## Procesos sin pantalla (background / servicio)
- Registro/refresh de token push en `PushService`.
- Conteo de no leídas para campana.
- Sync de widgets (al iniciar sesión, reanudar app y tras cambios).
- Presencia de chat de retos (`/me/presence/chat`) para política de notificación.

---

## Procesos de usuario app (paso a paso)

### 1) Iniciar sesión social (Google / Apple)
- **Qué hace:** autentica usuario en backend con proveedor social.
- **Dónde inicia:** `LoginScreen`.
- **Precondiciones:** app con internet y proveedor configurado.
- **Datos que debe ingresar:** selección de cuenta en Google/Apple (nativo).
- **Flujo principal paso a paso:**
  1. Usuario pulsa `Continuar con Google` o `Continuar con Apple`.
  2. SDK nativo devuelve token social.
  3. App llama `POST /api/v1/auth/social/login`.
  4. Backend retorna token de sesión y estado de onboarding.
  5. Si onboarding completo → entra a `MainShell`; si no → `OnboardingScreen`.
- **Flujos alternos/errores:** cancelación del proveedor, token inválido, DNS/backend caído.
- **Resultado esperado:** sesión activa en app.
- **Pantallas/popups involucrados:** `LoginScreen` + selector nativo proveedor.
- **Endpoints/API involucrados:** `POST /api/v1/auth/social/login`, `POST /api/v1/auth/logout`.
- **Estados que cambian:** sesión (`authenticated`/`unauthenticated`).

### 2) Completar onboarding
- **Qué hace:** obliga capturar datos mínimos iniciales.
- **Dónde inicia:** `OnboardingScreen` después de login social nuevo.
- **Precondiciones:** sesión activa con `needs_onboarding=true`.
- **Datos que debe ingresar:** `nick`, `sexo`.
- **Flujo principal paso a paso:**
  1. Usuario completa `nick` y `sexo`.
  2. Pulsa `Guardar y continuar`.
  3. App llama `POST /api/v1/onboarding`.
  4. Si OK, pasa a `MainShell`.
- **Flujos alternos/errores:** nick inválido/ocupado, error de red.
- **Resultado esperado:** perfil mínimo creado; acceso completo habilitado.
- **Pantallas/popups involucrados:** `OnboardingScreen`.
- **Endpoints/API involucrados:** `POST /api/v1/onboarding`.
- **Estados que cambian:** `needs_onboarding=false`.

### 3) Navegación principal + campana global
- **Qué hace:** navegación entre módulos y acceso rápido a notificaciones.
- **Dónde inicia:** `MainShell`.
- **Precondiciones:** sesión activa y onboarding completo.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. Usuario cambia entre tabs (`Mapa`, `Grupos`, `Pichangas`, `Inbox`, `Perfil`).
  2. Campana muestra `unread_count` con badge rojo.
  3. Tocar campana abre `Inbox` y refresca datos.
- **Flujos alternos/errores:** si falla carga de unread, badge puede mostrar `0` temporalmente.
- **Resultado esperado:** navegación consistente + badge persistente hasta lectura.
- **Pantallas/popups involucrados:** `MainShell`, `InboxScreen`.
- **Endpoints/API involucrados:** `GET /api/v1/me/notifications`.
- **Estados que cambian:** conteo `unread_count`.

### 4) Ver canchas en mapa
- **Qué hace:** visualiza canchas georreferenciadas como badges de precio.
- **Dónde inicia:** tab `Mapa`.
- **Precondiciones:** sesión activa.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. App consulta canchas con filtros activos.
  2. Renderiza Google Map.
  3. Crea marcadores con badge verde y precio (`S/ ...`).
- **Flujos alternos/errores:** error backend/map SDK muestra mensaje de error y reintento.
- **Resultado esperado:** mapa visible con canchas válidas.
- **Pantallas/popups involucrados:** `MapScreen`.
- **Endpoints/API involucrados:** `GET /api/v1/fields`.
- **Estados que cambian:** estado local de filtros/markers.

### 5) Buscar y filtrar canchas
- **Qué hace:** reduce resultados por superficie/formato/precio.
- **Dónde inicia:** card `Filtros de canchas` en `MapScreen`.
- **Precondiciones:** estar en mapa.
- **Datos que debe ingresar:**
  - tipos de superficie (`losa`, `sintético`, `artificial`),
  - formatos (`6v6`, `7v7`, `9v9`),
  - rango `precio min/max`.
- **Flujo principal paso a paso:**
  1. Usuario selecciona chips y/o precios.
  2. Pulsa `Aplicar`.
  3. App actualiza provider de filtros y vuelve a pedir `fields`.
  4. Mapa refresca marcadores.
- **Flujos alternos/errores:** `min > max` bloquea con snackbar.
- **Resultado esperado:** solo se muestran canchas que cumplen filtros.
- **Pantallas/popups involucrados:** `MapScreen` (sin popup).
- **Endpoints/API involucrados:** `GET /api/v1/fields?price_min&price_max&surface_types&vs_formats`.
- **Estados que cambian:** estado filtro en memoria.

### 6) Abrir detalle de cancha y acciones
- **Qué hace:** muestra datos de cancha + acciones rápidas.
- **Dónde inicia:** tap sobre marcador en `MapScreen`.
- **Precondiciones:** marcador visible.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. Toca marcador.
  2. Se abre bottom sheet con nombre, dirección, precio/contacto.
  3. Puede ejecutar: `Crear pichanga aquí`, `Favorito`, `Waze`, `Maps`.
- **Flujos alternos/errores:** si Waze/Maps no instalado, usa fallback; si falla, snackbar.
- **Resultado esperado:** navegación externa o acción interna según botón.
- **Pantallas/popups involucrados:** `MapScreen` + `BottomSheet` cancha.
- **Endpoints/API involucrados:**
  - `POST /api/v1/me/favorite-fields/{id}`
  - `DELETE /api/v1/me/favorite-fields/{id}`
- **Estados que cambian:** favorito de usuario por cancha.

### 7) Solicitar nueva cancha (moderación)
- **Qué hace:** crea solicitud de cancha para revisión admin.
- **Dónde inicia:** botón flotante `Agregar cancha` en `MapScreen`.
- **Precondiciones:** sesión activa.
- **Datos que debe ingresar:** nombre, dirección, lat/lng opcional, celular, whatsapp, precio, descripción.
- **Flujo principal paso a paso:**
  1. Abre diálogo `Solicitar nueva cancha`.
  2. Completa datos.
  3. Envía formulario.
  4. Backend crea `field_submission` en estado pendiente.
- **Flujos alternos/errores:** validaciones de nombre y payload.
- **Resultado esperado:** solicitud enviada para backoffice.
- **Pantallas/popups involucrados:** `MapScreen` + `AlertDialog`.
- **Endpoints/API involucrados:** `POST /api/v1/field-submissions`, `GET /api/v1/field-submissions/mine`.
- **Estados que cambian:** solicitud `pending`.

### 8) Listar grupos, buscar y descubrir
- **Qué hace:** muestra grupos propios y grupos visibles para descubrir.
- **Dónde inicia:** tab `Grupos` (`ClubsScreen`).
- **Precondiciones:** sesión activa.
- **Datos que debe ingresar:** texto de búsqueda opcional.
- **Flujo principal paso a paso:**
  1. Usuario usa buscador.
  2. Revisa tabs `Mis grupos` y `Descubrir`.
  3. Abre detalle del grupo o solicita ingreso (si visible y no miembro).
- **Flujos alternos/errores:** sin resultados, error de red.
- **Resultado esperado:** listado filtrado según scope.
- **Pantallas/popups involucrados:** `ClubsScreen`.
- **Endpoints/API involucrados:** `GET /api/v1/clubs?scope=mine|discover&q=...`.
- **Estados que cambian:** ninguno persistente.

### 9) Crear grupo
- **Qué hace:** crea nuevo grupo/club.
- **Dónde inicia:** botón `Crear` en `ClubsScreen`.
- **Precondiciones:** sesión activa.
- **Datos que debe ingresar:** nombre, descripción, visibilidad y settings base del grupo.
- **Flujo principal paso a paso:**
  1. Abre diálogo de creación.
  2. Completa campos.
  3. Envía.
  4. Backend crea grupo y membresía admin para creador.
- **Flujos alternos/errores:** nombre duplicado, validación.
- **Resultado esperado:** grupo visible en `Mis grupos`.
- **Pantallas/popups involucrados:** `ClubsScreen` + `AlertDialog` crear grupo.
- **Endpoints/API involucrados:** `POST /api/v1/clubs`.
- **Estados que cambian:** grupo creado + membership admin.

### 10) Gestionar invitaciones de grupo (recibidas)
- **Qué hace:** aceptar/rechazar invitaciones pendientes.
- **Dónde inicia:** card de invitaciones en `ClubsScreen`.
- **Precondiciones:** tener invitaciones pendientes.
- **Datos que debe ingresar:** acción `accept` o `reject`.
- **Flujo principal paso a paso:**
  1. Usuario toca `Aceptar` o `Rechazar`.
  2. App llama responder invitación.
  3. Refresca grupos e invitaciones.
- **Flujos alternos/errores:** invitación vencida o ya procesada.
- **Resultado esperado:** estado de invitación actualizado.
- **Pantallas/popups involucrados:** `ClubsScreen`.
- **Endpoints/API involucrados:** `GET /api/v1/invitations`, `POST /api/v1/invitations/{id}/respond`.
- **Estados que cambian:** invitación (`pending -> accepted|rejected`).

### 11) Ingresar a grupo por link
- **Qué hace:** preview y solicitud de ingreso por código/link.
- **Dónde inicia:** ícono link en `ClubsScreen` o deep-link `/join/{code}`.
- **Precondiciones:** código válido.
- **Datos que debe ingresar:** código o URL de join.
- **Flujo principal paso a paso:**
  1. Usuario pega código/link.
  2. Pulsa `Ver grupo`.
  3. App consulta preview.
  4. Si procede, pulsa `Solicitar ingreso`.
  5. Opcional: cancelar solicitud pendiente.
- **Flujos alternos/errores:** código inválido/rotado, acceso deshabilitado.
- **Resultado esperado:** solicitud `pending` o mensaje de membresía existente.
- **Pantallas/popups involucrados:** `JoinClubByLinkScreen`.
- **Endpoints/API involucrados:**
  - `GET /api/v1/clubs/join/{joinCode}`
  - `POST /api/v1/clubs/join/{joinCode}/request`
  - `POST /api/v1/clubs/{club}/join-requests/{request}/cancel`
- **Estados que cambian:** join request status.

### 12) Ver detalle de grupo
- **Qué hace:** concentra estado del grupo y módulos relacionados.
- **Dónde inicia:** tap en grupo desde listados.
- **Precondiciones:** tener acceso al grupo/visibilidad.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. Carga detalle del club + membership + settings.
  2. Muestra chips de privacidad/rol/permisos.
  3. Muestra bloques: solicitudes ingreso (admin), mute personal, miembros, pichangas.
- **Flujos alternos/errores:** acceso denegado o error carga.
- **Resultado esperado:** vista integral del grupo.
- **Pantallas/popups involucrados:** `ClubDetailScreen`.
- **Endpoints/API involucrados:**
  - `GET /api/v1/clubs/{id}`
  - `GET /api/v1/clubs/{id}/members`
  - `GET /api/v1/clubs/{id}/pichangas`
- **Estados que cambian:** ninguno si solo consulta.

### 13) Invitar usuario al grupo (admin)
- **Qué hace:** envía invitación por nick o email.
- **Dónde inicia:** botón `Invitar` en `ClubDetailScreen`.
- **Precondiciones:** rol admin/super en grupo.
- **Datos que debe ingresar:** `nick` o `email`.
- **Flujo principal paso a paso:**
  1. Abre diálogo `Invitar usuario`.
  2. Completa nick/email.
  3. Envía invitación.
- **Flujos alternos/errores:** no admin, usuario no encontrado, ya miembro.
- **Resultado esperado:** invitación pendiente para el usuario objetivo.
- **Pantallas/popups involucrados:** `ClubDetailScreen` + `AlertDialog`.
- **Endpoints/API involucrados:** `POST /api/v1/clubs/{id}/invitations`.
- **Estados que cambian:** invitación creada.

### 14) Gestionar solicitudes de ingreso (admin)
- **Qué hace:** aceptar/rechazar solicitudes al grupo.
- **Dónde inicia:** card `Solicitudes de ingreso` en `ClubDetailScreen`.
- **Precondiciones:** rol admin en grupo.
- **Datos que debe ingresar:** acción `accept` o `reject`.
- **Flujo principal paso a paso:**
  1. Admin revisa lista y vía de solicitud (search/link).
  2. Toca check o close por solicitud.
  3. Sistema procesa decisión.
- **Flujos alternos/errores:** solicitud ya resuelta.
- **Resultado esperado:** solicitud resuelta y membresía creada si `accept`.
- **Pantallas/popups involucrados:** `ClubDetailScreen`.
- **Endpoints/API involucrados:**
  - `GET /api/v1/clubs/{id}/join-requests`
  - `POST /api/v1/clubs/{id}/join-requests/{request}/decision`
- **Estados que cambian:** join request y club membership.

### 15) Configurar notificaciones por grupo (mute personal)
- **Qué hace:** define si el usuario recibe push para ese grupo.
- **Dónde inicia:** card `Notificaciones de este grupo` en `ClubDetailScreen`.
- **Precondiciones:** ser miembro del grupo.
- **Datos que debe ingresar:** modo `always_on`, `mute_24h`, `mute_1w`, `mute_forever`.
- **Flujo principal paso a paso:**
  1. App carga preferencia actual.
  2. Usuario selecciona nuevo modo.
  3. App guarda y refresca estado.
- **Flujos alternos/errores:** falta membresía o error de red.
- **Resultado esperado:** push filtrado por preferencia personal del grupo.
- **Pantallas/popups involucrados:** `ClubDetailScreen`.
- **Endpoints/API involucrados:**
  - `GET /api/v1/clubs/{id}/notification-preference`
  - `PUT /api/v1/clubs/{id}/notification-preference`
- **Estados que cambian:** preferencia de notificación por usuario+grupo.

### 16) Configurar growth del grupo (admin)
- **Qué hace:** maneja link de ingreso y avisos automáticos.
- **Dónde inicia:** sección `Growth` en `ClubDetailScreen` (admin).
- **Precondiciones:** rol admin.
- **Datos que debe ingresar:** toggles de link join y auto reminders.
- **Flujo principal paso a paso:**
  1. Admin copia link de ingreso.
  2. Opcional rota código/link.
  3. Activa/desactiva `link_join_enabled`, `auto_reminder_enabled`, `48h`, `24h`.
- **Flujos alternos/errores:** permisos insuficientes.
- **Resultado esperado:** configuración persistida en club.
- **Pantallas/popups involucrados:** `ClubDetailScreen`.
- **Endpoints/API involucrados:**
  - `POST /api/v1/clubs/{id}/join-code/rotate`
  - `PUT /api/v1/clubs/{id}`
- **Estados que cambian:** settings del club y join_code.

### 17) Crear reto entre grupos
- **Qué hace:** crea challenge entre grupo origen y grupo destino.
- **Dónde inicia:** botón `Retar grupo` (en grupos visibles donde usuario no es miembro).
- **Precondiciones:** pertenecer al menos a un grupo propio.
- **Datos que debe ingresar:** grupo origen, tamaño equipo, ventana de reto, nota.
- **Flujo principal paso a paso:**
  1. Abre diálogo `Retar a ...`.
  2. Selecciona parámetros.
  3. Envía reto.
- **Flujos alternos/errores:** sin grupo propio, grupo no elegible.
- **Resultado esperado:** challenge `pending` y notificación al grupo retado.
- **Pantallas/popups involucrados:** `ClubDetailScreen` + `AlertDialog`.
- **Endpoints/API involucrados:** `POST /api/v1/clubs/{id}/challenges`.
- **Estados que cambian:** challenge creado.

### 18) Ver listado de retos
- **Qué hace:** muestra retos donde participa el usuario por sus grupos.
- **Dónde inicia:** pantalla `Retos`.
- **Precondiciones:** sesión activa.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. App consulta retos del usuario.
  2. Muestra cards con estado y teams.
  3. Tap abre detalle del reto.
- **Flujos alternos/errores:** sin retos activos.
- **Resultado esperado:** acceso a coordinación y chat.
- **Pantallas/popups involucrados:** `ChallengesScreen`.
- **Endpoints/API involucrados:** `GET /api/v1/challenges`.
- **Estados que cambian:** ninguno.

### 19) Coordinar/rechazar/cancelar reto
- **Qué hace:** avanza o termina un reto según rol/lado.
- **Dónde inicia:** `ChallengeDetailScreen`.
- **Precondiciones:** pertenecer a alguno de los grupos del reto.
- **Datos que debe ingresar:** motivo opcional en rechazo/cancelación.
- **Flujo principal paso a paso:**
  1. Usuario abre detalle del reto.
  2. Ejecuta acción permitida (`coordinate`, `reject`, `cancel`).
  3. Estado se actualiza y se registran mensajes/eventos.
- **Flujos alternos/errores:** acción no permitida por lado del reto.
- **Resultado esperado:** estado del challenge actualizado.
- **Pantallas/popups involucrados:** `ChallengeDetailScreen` (+ diálogo de motivo según acción).
- **Endpoints/API involucrados:**
  - `POST /api/v1/challenges/{id}/coordinate`
  - `POST /api/v1/challenges/{id}/reject`
  - `POST /api/v1/challenges/{id}/cancel`
- **Estados que cambian:** challenge status.

### 20) Chat de reto + presencia
- **Qué hace:** conversación entre grupos con notificación contextual.
- **Dónde inicia:** `ChallengeDetailScreen` sección chat.
- **Precondiciones:** acceso al reto.
- **Datos que debe ingresar:** texto mensaje.
- **Flujo principal paso a paso:**
  1. App abre mensajes del reto.
  2. Envía mensajes con `sendMessage`.
  3. Mantiene heartbeat de presencia (`/me/presence/chat`).
  4. Si receptor no está en chat activo, se notifica por push/inbox.
- **Flujos alternos/errores:** pérdida de red o sesión.
- **Resultado esperado:** mensajes persistidos y notificación según contexto.
- **Pantallas/popups involucrados:** `ChallengeDetailScreen`.
- **Endpoints/API involucrados:**
  - `GET /api/v1/challenges/{id}/messages`
  - `POST /api/v1/challenges/{id}/messages`
  - `PUT /api/v1/me/presence/chat`
- **Estados que cambian:** mensajes, unread y presencia.

### 21) Proponer cancha/horario/configuración de reto
- **Qué hace:** propone y decide configuración para cerrar reto.
- **Dónde inicia:** `ChallengeDetailScreen` (diálogos de propuesta/decisión).
- **Precondiciones:** reto activo y permisos por lado.
- **Datos que debe ingresar:**
  - opciones de cancha,
  - opciones de horario,
  - configuración final (field/time/link invitados).
- **Flujo principal paso a paso:**
  1. Usuario propone opciones.
  2. Contraparte decide (`accept`/`reject`).
  3. Al aceptar configuración final, se crea pichanga vinculada al reto.
- **Flujos alternos/errores:** conflicto de estado o permisos.
- **Resultado esperado:** coordinación documentada y pichanga resultante.
- **Pantallas/popups involucrados:** `ChallengeDetailScreen` + varios `AlertDialog`.
- **Endpoints/API involucrados:**
  - `POST /api/v1/challenges/{id}/field-options`
  - `POST /api/v1/challenges/{id}/time-options`
  - `GET /api/v1/challenges/{id}/configurations`
  - `POST /api/v1/challenges/{id}/configurations/propose`
  - `POST /api/v1/challenges/{id}/configurations/{cfg}/decision`
- **Estados que cambian:** opciones/configuraciones/challenge.

### 22) Crear pichanga
- **Qué hace:** crea una pichanga en un grupo.
- **Dónde inicia:** botón `Crear pichanga` desde grupo o cancha.
- **Precondiciones:** permisos de creación en el grupo.
- **Datos que debe ingresar:**
  - grupo,
  - título,
  - descripción,
  - cancha (`field_id`) y dirección,
  - formato (`versus|triangular|cuadrangular`),
  - jugadores por equipo (5..11),
  - duración,
  - fecha/hora,
  - modo confirmación,
  - abierta sí/no,
  - solicitudes externas sí/no,
  - auto reminders sí/no,
  - grado notificación,
  - filtros audiencia (sexo/edad).
- **Flujo principal paso a paso:**
  1. Usuario completa formulario.
  2. App deriva cupos (`capacity`) por formato y jugadores/equipo.
  3. Envía payload al backend.
  4. Backend crea pichanga y devuelve detalle.
- **Flujos alternos/errores:** permisos insuficientes, validaciones.
- **Resultado esperado:** pichanga creada, visible en listas.
- **Pantallas/popups involucrados:** `CreatePichangaScreen` + date picker.
- **Endpoints/API involucrados:** `POST /api/v1/clubs/{club}/pichangas`.
- **Estados que cambian:** pichanga `pending|confirmed` según lógica.

### 23) Ver pichangas del grupo / disponibles
- **Qué hace:** consulta pichangas por contexto.
- **Dónde inicia:** `ClubDetailScreen` o tab `Pichangas`.
- **Precondiciones:** sesión activa.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. App pide lista por club o disponibles.
  2. Usuario abre detalle de una pichanga.
- **Flujos alternos/errores:** sin resultados o error red.
- **Resultado esperado:** acceso a detalle y acciones.
- **Pantallas/popups involucrados:** `ClubDetailScreen`, `PichangasScreen`.
- **Endpoints/API involucrados:**
  - `GET /api/v1/clubs/{club}/pichangas`
  - `GET /api/v1/pichangas/available`
- **Estados que cambian:** ninguno.

### 24) Confirmar asistencia por equipo/slot
- **Qué hace:** confirma participación eligiendo equipo (`A/B/C/D`).
- **Dónde inicia:** `PichangaDetailScreen` tablero de equipos.
- **Precondiciones:** ser miembro del grupo (o flujo externo aprobado).
- **Datos que debe ingresar:** equipo seleccionado.
- **Flujo principal paso a paso:**
  1. Usuario selecciona tarjeta de equipo.
  2. Ve preview de ubicación en siguiente slot.
  3. Pulsa `Confirmar en equipo X`.
  4. Backend confirma y asigna `team_code/team_slot`.
- **Flujos alternos/errores:** pichanga llena, permisos, estado inválido.
- **Resultado esperado:** estado `confirmed` con equipo/slot.
- **Pantallas/popups involucrados:** `PichangaDetailScreen`.
- **Endpoints/API involucrados:** `POST /api/v1/pichangas/{id}/confirm`.
- **Estados que cambian:** participant status + team assignment.

### 25) Cambiar equipo o darse de baja
- **Qué hace:** mueve confirmado a otro equipo o retira asistencia.
- **Dónde inicia:** `PichangaDetailScreen`.
- **Precondiciones:** estar confirmado.
- **Datos que debe ingresar:** equipo nuevo (si cambio).
- **Flujo principal paso a paso:**
  1. Usuario selecciona otro equipo y pulsa `Cambiar al equipo X`.
  2. O pulsa `Darme de baja`.
  3. Backend actualiza estado/slot.
- **Flujos alternos/errores:** reglas de plazo de baja o estado no válido.
- **Resultado esperado:** cambio aplicado y tablero actualizado.
- **Pantallas/popups involucrados:** `PichangaDetailScreen`.
- **Endpoints/API involucrados:**
  - `POST /api/v1/pichangas/{id}/confirm` (cambio)
  - `POST /api/v1/pichangas/{id}/withdraw`
- **Estados que cambian:** confirmed/withdrawn + team data.

### 26) Solicitudes externas a pichanga
- **Qué hace:** permite solicitar cupo si no eres miembro; admin decide.
- **Dónde inicia:** botón `Solicitar cupo` en detalle pichanga.
- **Precondiciones:** no ser miembro y pichanga con externos permitidos.
- **Datos que debe ingresar:** ninguno (solicitud simple).
- **Flujo principal paso a paso:**
  1. Usuario externo crea solicitud.
  2. Admin ve lista `Solicitudes externas`.
  3. Admin acepta o rechaza.
- **Flujos alternos/errores:** solicitud duplicada o pichanga cerrada.
- **Resultado esperado:** solicitud resuelta; si aceptada, participa.
- **Pantallas/popups involucrados:** `PichangaDetailScreen`.
- **Endpoints/API involucrados:**
  - `POST /api/v1/pichangas/{id}/external-requests`
  - `GET /api/v1/pichangas/{id}/external-requests`
  - `POST /api/v1/pichangas/{id}/external-requests/{request}/decision`
- **Estados que cambian:** external request status.

### 27) Re-avisar pichanga (manual con preview)
- **Qué hace:** reenvía invitaciones según grado/filtros.
- **Dónde inicia:** botón `Avisar de nuevo` en detalle pichanga.
- **Precondiciones:** permiso por política del grupo.
- **Datos que debe ingresar:** grado, sexo, edad, skills mínimos.
- **Flujo principal paso a paso:**
  1. Abre diálogo `Avisar de nuevo`.
  2. Configura filtros.
  3. Pulsa preview para ver alcance estimado.
  4. Pulsa send para ejecutar envío real.
- **Flujos alternos/errores:** cooldown/topes/política de grupo.
- **Resultado esperado:** batch auditado y notificaciones encoladas.
- **Pantallas/popups involucrados:** `PichangaDetailScreen` + `AlertDialog`.
- **Endpoints/API involucrados:**
  - `POST /api/v1/pichangas/{id}/renotify/preview`
  - `POST /api/v1/pichangas/{id}/renotify/send`
- **Estados que cambian:** batches de notificación + inbox/push.

### 28) Feed social de pichanga
- **Qué hace:** publicar texto y comentarios dentro de la pichanga.
- **Dónde inicia:** card `Feed` en `PichangaDetailScreen`.
- **Precondiciones:** acceso a la pichanga.
- **Datos que debe ingresar:** texto de post o comentario.
- **Flujo principal paso a paso:**
  1. Usuario abre diálogo de post o comentario.
  2. Envía texto.
  3. Feed se invalida y recarga.
- **Flujos alternos/errores:** validación de longitud/permisos.
- **Resultado esperado:** item visible en feed.
- **Pantallas/popups involucrados:** `PichangaDetailScreen` + diálogos de post/comentario.
- **Endpoints/API involucrados:**
  - `GET /api/v1/pichangas/{id}/feed`
  - `POST /api/v1/pichangas/{id}/feed/posts`
  - `DELETE /api/v1/pichangas/{id}/feed/posts/{post}`
  - `POST /api/v1/pichangas/{id}/feed/posts/{post}/comments`
  - `DELETE /api/v1/pichangas/{id}/feed/posts/{post}/comments/{comment}`
- **Estados que cambian:** posts/comments.

### 29) Calificar jugadores de pichanga
- **Qué hace:** registra calificaciones por skills con decimales.
- **Dónde inicia:** card `Calificaciones` en `PichangaDetailScreen`.
- **Precondiciones:** acceso a pichanga y reglas de calificación.
- **Datos que debe ingresar:** `fisico`, `arquero`, `delantero`, `mediocampo`, `defensa` (0.0–10.0, 1 decimal).
- **Flujo principal paso a paso:**
  1. Abre diálogo de calificación.
  2. Ajusta sliders por skill.
  3. Envía.
  4. Lista de ratings se refresca.
- **Flujos alternos/errores:** límites/frecuencia/permisos.
- **Resultado esperado:** rating guardado o actualizado.
- **Pantallas/popups involucrados:** `PichangaDetailScreen` + `AlertDialog` rating.
- **Endpoints/API involucrados:**
  - `POST /api/v1/pichangas/{id}/ratings`
  - `GET /api/v1/pichangas/{id}/ratings`
- **Estados que cambian:** ratings por pichanga.

### 30) Gestionar inbox y deep-link
- **Qué hace:** centraliza notificaciones y navegación al evento.
- **Dónde inicia:** tab `Inbox` o campana.
- **Precondiciones:** sesión activa.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. Usuario ve listado de notificaciones.
  2. Puede `Marcar todo leído`.
  3. O abrir una notificación individual.
  4. App marca leída y navega a pichanga o chat de reto según `data_json`.
- **Flujos alternos/errores:** payload sin destino abre solo lectura.
- **Resultado esperado:** badge disminuye y navegación correcta.
- **Pantallas/popups involucrados:** `InboxScreen`.
- **Endpoints/API involucrados:**
  - `GET /api/v1/me/notifications`
  - `POST /api/v1/me/notifications/read-all`
  - `POST /api/v1/me/notifications/{id}/read`
- **Estados que cambian:** `is_read` + unread_count.

### 31) Ver y editar perfil
- **Qué hace:** muestra datos de usuario y permite edición de datos base.
- **Dónde inicia:** tab `Perfil`.
- **Precondiciones:** sesión activa.
- **Datos que debe ingresar:** nickname, sexo, fecha nacimiento, altura, etc. (según formulario).
- **Flujo principal paso a paso:**
  1. Usuario abre perfil.
  2. Toca ícono editar.
  3. Actualiza campos.
  4. Guarda y refresca datos.
- **Flujos alternos/errores:** validaciones de backend.
- **Resultado esperado:** perfil actualizado.
- **Pantallas/popups involucrados:** `ProfileScreen` + `AlertDialog` editar.
- **Endpoints/API involucrados:** `GET /api/v1/me`, `PUT /api/v1/me`.
- **Estados que cambian:** datos del perfil.

### 32) Historial de pichangas y canchas favoritas en perfil
- **Qué hace:** consulta historial personal y favoritos.
- **Dónde inicia:** `ProfileScreen`.
- **Precondiciones:** sesión activa.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. App carga historial (`me/pichangas/history`).
  2. App carga favoritos (`me/favorite-fields`).
  3. Usuario puede remover favorito desde perfil.
- **Flujos alternos/errores:** listas vacías.
- **Resultado esperado:** historial y favoritos actualizados.
- **Pantallas/popups involucrados:** `ProfileScreen`.
- **Endpoints/API involucrados:**
  - `GET /api/v1/me/pichangas/history`
  - `GET /api/v1/me/favorite-fields`
  - `DELETE /api/v1/me/favorite-fields/{id}`
- **Estados que cambian:** favoritos del usuario.

### 33) Subir clip de perfil (video)
- **Qué hace:** crea clip vertical comprimido desde video local.
- **Dónde inicia:** botón `Subir clip` en `ProfileScreen`.
- **Precondiciones:** máximo 5 clips activos; permisos galería.
- **Datos que debe ingresar:**
  - selección de video fuente,
  - tramo exacto de 7s (si video > 7s),
  - título opcional.
- **Flujo principal paso a paso:**
  1. Selecciona video local.
  2. Validación duración fuente (7–20s).
  3. Si duración >7s, abre popup para elegir tramo.
  4. App procesa clip local (vertical 9:16, compresión, audio).
  5. Sube MP4 final al backend.
- **Flujos alternos/errores:** peso excedido, `has_audio` inválido, cancelación del diálogo.
- **Resultado esperado:** clip aparece en lista con preview y metadatos.
- **Pantallas/popups involucrados:** `ProfileScreen` + dialog de tramo 7s.
- **Endpoints/API involucrados:**
  - `GET /api/v1/me/profile-clips`
  - `POST /api/v1/me/profile-clips`
- **Estados que cambian:** clips del usuario.

### 34) Reordenar, eliminar y ver clip en fullscreen
- **Qué hace:** administra clips existentes.
- **Dónde inicia:** sección `Mis clips de perfil`.
- **Precondiciones:** tener clips.
- **Datos que debe ingresar:** nuevo orden (drag & drop) o acción de eliminar.
- **Flujo principal paso a paso:**
  1. Reordena con drag handle.
  2. App envía nuevo orden.
  3. Puede eliminar con ícono tacho.
  4. Tap en preview abre reproducción fullscreen.
- **Flujos alternos/errores:** error reorder/delete.
- **Resultado esperado:** orden y contenido persistidos.
- **Pantallas/popups involucrados:** `ProfileScreen`, `ProfileClipFullscreenPage`.
- **Endpoints/API involucrados:**
  - `PUT /api/v1/me/profile-clips/reorder`
  - `DELETE /api/v1/me/profile-clips/{id}`
  - `GET /api/v1/users/{user}/profile-clips` (vista pública)
- **Estados que cambian:** `sort_order` y `status` del clip.

### 35) Widget + compartir pichanga
- **Qué hace:** permite usar pichanga confirmada en widget y compartirla.
- **Dónde inicia:** acción de widget o pantalla `PichangaWidgetShareScreen`.
- **Precondiciones:** pichanga confirmada disponible.
- **Datos que debe ingresar:** selección de acción (`share link` o `share lineup`).
- **Flujo principal paso a paso:**
  1. Servicio widget sincroniza pichangas confirmadas.
  2. Usuario toca acción del widget.
  3. App abre `PichangaWidgetShareScreen`.
  4. Comparte link o imagen de alineación (`Canchita`).
- **Flujos alternos/errores:** sin pichangas confirmadas, fallo de share.
- **Resultado esperado:** contenido compartido a apps externas.
- **Pantallas/popups involucrados:** `PichangaWidgetShareScreen` + integraciones nativas widget.
- **Endpoints/API involucrados:**
  - `GET /api/v1/pichangas/widget/confirmed-next`
  - `GET /api/v1/pichangas/{id}` (para detalle al compartir)
- **Estados que cambian:** selección y payload de widget en almacenamiento compartido.

---

## Procesos web superadmin/staff (backoffice)

> Alcance web de este documento: solo rutas bajo `/admin/*` con middleware `auth + admin.backoffice`.

### 1) Acceso al backoffice
- **Qué hace:** habilita panel administrativo web.
- **Dónde inicia:** `GET /admin`.
- **Precondiciones:** usuario logueado y perfil `superadmin` o `staff_admin`.
- **Datos que debe ingresar:** credenciales web (login Laravel).
- **Flujo principal paso a paso:**
  1. Login web.
  2. Middleware valida acceso backoffice.
  3. Abre dashboard admin.
- **Flujos alternos/errores:** 403 si no tiene rol backoffice.
- **Resultado esperado:** acceso permitido solo a roles admin.
- **Pantallas/popups involucrados:** vistas blade admin.
- **Endpoints/API involucrados:** rutas web `/admin/*`.
- **Estados que cambian:** sesión web.

### 2) Dashboard operativo
- **Qué hace:** muestra backlog de moderación + salud operativa + growth resumen.
- **Dónde inicia:** `/admin`.
- **Precondiciones:** acceso backoffice.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. Carga métricas de pendientes y jobs.
  2. Carga readiness (colas, push, well-known, etc.).
  3. Carga resumen growth últimos días.
- **Flujos alternos/errores:** tablas faltantes devuelven contadores `0`.
- **Resultado esperado:** panel de control operativo.
- **Pantallas/popups involucrados:** `admin.dashboard`.
- **Endpoints/API involucrados:** cálculo interno controller (sin API externa obligatoria).
- **Estados que cambian:** ninguno.

### 3) Moderar reportes (individual y masivo)
- **Qué hace:** filtra y resuelve reportes de usuarios/contenido.
- **Dónde inicia:** `/admin/reports`.
- **Precondiciones:** acceso backoffice.
- **Datos que debe ingresar:** filtros (`status`, `target_type`, `q`) y acción de resolución.
- **Flujo principal paso a paso:**
  1. Admin aplica filtros.
  2. Resuelve uno a uno o selección masiva (`ids[]`).
  3. Define estado final y nota.
- **Flujos alternos/errores:** ítems ya resueltos pasan a `skipped` en bulk.
- **Resultado esperado:** reportes actualizados con auditoría.
- **Pantallas/popups involucrados:** `admin.reports`.
- **Endpoints/API involucrados:**
  - Web: `POST /admin/reports/{report}/resolve`, `POST /admin/reports/bulk-resolve`
  - API admin equivalente disponible en `/api/v1/admin/reports*`
- **Estados que cambian:** report `status`, `resolved_by`, `resolved_at`.

### 4) Moderar solicitudes de canchas (individual y masivo)
- **Qué hace:** aprueba/rechaza submissions de canchas.
- **Dónde inicia:** `/admin/field-submissions`.
- **Precondiciones:** acceso backoffice.
- **Datos que debe ingresar:** filtros, acción (`approve/reject`), nota.
- **Flujo principal paso a paso:**
  1. Filtra solicitudes.
  2. Ejecuta decisión individual o bulk.
  3. Si `approve`, se materializa en `polideportivo`.
- **Flujos alternos/errores:** solicitud no pendiente se salta.
- **Resultado esperado:** cola de moderación procesada.
- **Pantallas/popups involucrados:** `admin.field_submissions`.
- **Endpoints/API involucrados:**
  - Web: `POST /admin/field-submissions/{submission}/decision`, `POST /admin/field-submissions/bulk-decision`
  - API admin equivalente en `/api/v1/admin/field-submissions*`
- **Estados que cambian:** field submission `pending|approved|rejected`.

### 5) Gestionar strikes
- **Qué hace:** emitir/revocar strikes con restricciones por rol.
- **Dónde inicia:** `/admin/strikes`.
- **Precondiciones:** acceso backoffice.
- **Datos que debe ingresar:**
  - issue: `user_id`, `reason_code`, opcional `report_id`, descripción, días,
  - revoke: nota de revocación.
- **Flujo principal paso a paso:**
  1. Aplica strike manual o por reporte.
  2. Filtra listado de strikes.
  3. Revoca individual o masivo según permisos.
- **Flujos alternos/errores:**
  - `staff_admin` no puede revocar strikes críticos ni actuar sobre cuentas backoffice en casos bloqueados.
- **Resultado esperado:** estado de strike actualizado y auditado.
- **Pantallas/popups involucrados:** `admin.strikes`.
- **Endpoints/API involucrados:**
  - Web: `POST /admin/strikes`, `POST /admin/strikes/{strike}/revoke`, `POST /admin/strikes/bulk-revoke`
  - API admin equivalente en `/api/v1/admin/strikes*`
- **Estados que cambian:** strike `active|revoked`.

### 6) Suspender usuario (solo superadmin)
- **Qué hace:** aplica suspensión manual temporal/indefinida.
- **Dónde inicia:** acción de suspensión admin.
- **Precondiciones:** rol `superadmin`.
- **Datos que debe ingresar:** `suspended_until`, `suspension_reason`.
- **Flujo principal paso a paso:**
  1. Superadmin define fecha/razón.
  2. Ejecuta actualización.
- **Flujos alternos/errores:**
  - staff recibe 403,
  - actor no puede suspenderse a sí mismo.
- **Resultado esperado:** usuario suspendido según política.
- **Pantallas/popups involucrados:** acciones admin de backoffice.
- **Endpoints/API involucrados:**
  - Web: `POST /admin/users/{user}/suspension`
  - API: `POST /api/v1/admin/users/{user}/suspension`
- **Estados que cambian:** `users.suspended_until`, `users.suspension_reason`.

### 7) Métricas growth
- **Qué hace:** muestra agregados por rango de fechas.
- **Dónde inicia:** `/admin/metrics/growth`.
- **Precondiciones:** acceso backoffice.
- **Datos que debe ingresar:** `from`, `to`.
- **Flujo principal paso a paso:**
  1. Selecciona rango.
  2. Pulsa actualizar.
  3. Visualiza agregados diarios/eventos.
- **Flujos alternos/errores:** rango inválido (`from > to`) devuelve error.
- **Resultado esperado:** tablero de crecimiento consultable.
- **Pantallas/popups involucrados:** `admin.metrics_growth`.
- **Endpoints/API involucrados:**
  - Web view controller
  - API: `GET /api/v1/admin/metrics/growth`
- **Estados que cambian:** ninguno.

### 8) Ops readiness
- **Qué hace:** valida estado operativo (colas/jobs/push/well-known).
- **Dónde inicia:** `/admin/ops/readiness`.
- **Precondiciones:** acceso backoffice.
- **Datos que debe ingresar:** ninguno.
- **Flujo principal paso a paso:**
  1. Abre módulo readiness.
  2. Revisa `queue_connection`, `jobs_pending`, `failed_jobs_count`, `push_driver`, etc.
  3. Usa `Refrescar` para estado actual.
- **Flujos alternos/errores:** degradación si servicios no disponibles.
- **Resultado esperado:** diagnóstico operativo rápido.
- **Pantallas/popups involucrados:** `admin.ops_readiness`.
- **Endpoints/API involucrados:** `GET /api/v1/admin/ops/release-readiness`.
- **Estados que cambian:** ninguno.

---

## Matriz permisos admin (web backoffice)

| Proceso | staff_admin | superadmin |
|---|---:|---:|
| Ver dashboard, métricas, ops readiness | ✅ | ✅ |
| Resolver reportes (single/bulk) | ✅ | ✅ |
| Decidir solicitudes de cancha (single/bulk) | ✅ | ✅ |
| Emitir strike | ✅ (con restricciones) | ✅ |
| Revocar strike | ✅ (no críticos bloqueados) | ✅ |
| Revocar strike masivo | ✅ (con `skipped` bloqueados) | ✅ |
| Suspender usuario manualmente | ❌ | ✅ |
| Acciones críticas sobre cuentas backoffice | restringido | ✅ |

---

## Matriz proceso → pantalla/popup → endpoint

| Proceso | UI principal | Tipo UI | Endpoint(s) clave |
|---|---|---|---|
| Login social | `LoginScreen` | Pantalla + nativo | `POST /api/v1/auth/social/login` |
| Onboarding | `OnboardingScreen` | Pantalla | `POST /api/v1/onboarding` |
| Mapa + filtros | `MapScreen` | Pantalla | `GET /api/v1/fields` |
| Detalle cancha | `MapScreen` | Bottom sheet | favoritos + navegación externa |
| Solicitar cancha | `MapScreen` | Popup | `POST /api/v1/field-submissions` |
| Crear grupo | `ClubsScreen` | Popup | `POST /api/v1/clubs` |
| Join por link | `JoinClubByLinkScreen` | Pantalla | `GET/POST /api/v1/clubs/join/*` |
| Invitaciones | `ClubsScreen` | Card inline | `GET/POST /api/v1/invitations*` |
| Detalle grupo | `ClubDetailScreen` | Pantalla | `GET /api/v1/clubs/{id}` |
| Join requests admin | `ClubDetailScreen` | Inline acciones | `POST /api/v1/clubs/{id}/join-requests/*/decision` |
| Mute por grupo | `ClubDetailScreen` | Inline form | `GET/PUT /api/v1/clubs/{id}/notification-preference` |
| Retos listado | `ChallengesScreen` | Pantalla | `GET /api/v1/challenges` |
| Chat de reto | `ChallengeDetailScreen` | Pantalla | mensajes + presencia |
| Crear pichanga | `CreatePichangaScreen` | Pantalla | `POST /api/v1/clubs/{id}/pichangas` |
| Confirmar/cambiar equipo | `PichangaDetailScreen` | Inline acciones | `POST /api/v1/pichangas/{id}/confirm` |
| Baja pichanga | `PichangaDetailScreen` | Inline acción | `POST /api/v1/pichangas/{id}/withdraw` |
| Solicitudes externas | `PichangaDetailScreen` | Inline acciones | `external-requests` |
| Re-avisar | `PichangaDetailScreen` | Popup | `renotify/preview`, `renotify/send` |
| Feed social | `PichangaDetailScreen` | Popups + lista | `feed/posts/comments` |
| Ratings pichanga | `PichangaDetailScreen` | Popup | `POST /api/v1/pichangas/{id}/ratings` |
| Inbox | `InboxScreen` | Pantalla | `GET /api/v1/me/notifications` |
| Clips de perfil | `ProfileScreen` | Pantalla + popup + fullscreen | `me/profile-clips*` |
| Widget share | `PichangaWidgetShareScreen` | Pantalla | `GET /api/v1/pichangas/widget/confirmed-next` |
| Backoffice reportes | `admin.reports` | Web | `/admin/reports*` |
| Backoffice solicitudes cancha | `admin.field_submissions` | Web | `/admin/field-submissions*` |
| Backoffice strikes | `admin.strikes` | Web | `/admin/strikes*` |
| Backoffice ops | `admin.ops_readiness` | Web | `/api/v1/admin/ops/release-readiness` |

---

## Checklist de validación funcional

## App usuario
- [ ] Login Google y Apple operativos.
- [ ] Onboarding obliga `nick + sexo` en usuario nuevo.
- [ ] Campana muestra badge rojo y baja al leer.
- [ ] Mapa carga canchas y filtros aplican correctamente.
- [ ] Bottom sheet de cancha ejecuta crear pichanga/favorito/Waze/Maps.
- [ ] Crear grupo, invitar, aceptar/rechazar invitaciones.
- [ ] Join por link: preview, solicitar y cancelar solicitud.
- [ ] Notificación por grupo configurable (always_on/24h/1w/forever).
- [ ] Crear reto + chat + coordinación + decisión de configuración.
- [ ] Crear pichanga con formato y players/equipo.
- [ ] Confirmar por equipo, cambiar equipo y darse de baja.
- [ ] Solicitudes externas: crear y decidir.
- [ ] Renotify preview/send funcional.
- [ ] Feed (post/comentario) y ratings pichanga funcionales.
- [ ] Clips: subir 7s, reorder, eliminar, fullscreen.
- [ ] Widget: selección y compartir link/alineación.

## Web superadmin/staff
- [ ] Acceso restringido a backoffice (`superadmin`/`staff_admin`).
- [ ] Dashboard con stats + readiness.
- [ ] Reportes: filtros + single/bulk resolve.
- [ ] Solicitudes cancha: filtros + single/bulk decision.
- [ ] Strikes: issue + revoke + bulk revoke con restricciones staff.
- [ ] Suspensión de usuario solo para superadmin.
- [ ] Métricas growth por rango.
- [ ] Ops readiness con datos actualizados.

---

## Notas de disponibilidad condicionada
- Algunas acciones dependen de rol (`admin de grupo`, `superadmin`, `staff_admin`).
- Algunas acciones dependen de estado (`miembro/no miembro`, `pendiente/confirmado`, `pending/accepted/rejected`).
- Push y badge dependen de configuración de notificaciones del dispositivo y de preferencias por grupo.
