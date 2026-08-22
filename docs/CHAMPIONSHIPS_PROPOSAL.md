# Campeonatos Fulbii

## Objetivo

Incorporar campeonatos organizados sobre la lógica existente de Fulbii: grupos,
pichangas, equipos, canchas, formaciones, calificaciones, notificaciones y
estadísticas de jugador.

La primera versión operativa soporta **liga por puntos** (una vuelta o ida y
vuelta) y una base de **llaves de eliminación** con avance automático del
ganador. El formato híbrido queda modelado y se habilitará por fases cuando se
definan sus reglas de clasificación.

## Estado de esta primera entrega técnica

El contrato y las tablas están en `database/migrations/2026_08_21_000002_create_championship_tables.php` y la compatibilidad de llaves en
`database/migrations/2026_08_21_000003_extend_championship_brackets.php`; ambas
deben ejecutarse explícitamente en cada entorno. La web ya cubre la operación
principal: crear y publicar, abrir inscripciones, delegar gestores, crear
equipos, invitar jugadores, generar/revisar fixture, programar jornadas y
partidos por sede/cancha, vincular cada partido a una pichanga y registrar
resultados con acta JSON y auditoría. La app ya permite visualizar tabla,
fixture, estado en vivo, equipos, plantillas, estadísticas, invitaciones y
abrir la pichanga asociada.

La app prioriza la visualización y las respuestas de invitación. Quedan
explícitamente diferidos para una siguiente entrega los flujos transaccionales
completos desde app (crear campeonato, cerrar inscripción, regenerar fixture,
programar sedes, registrar acta/eventos y resolver desempates), además del
marcador en vivo con websocket/presencia. Esas operaciones permanecen en la
web/API con permisos protegidos para no bloquear la primera publicación móvil.

### Qué se puede hacer en cada cliente

| Capacidad | Web/backoffice | App Flutter (primera entrega) |
| --- | --- | --- |
| Crear y publicar campeonato | Sí, superadmin | Visualiza lo publicado |
| Delegar gestores y permisos | Sí, superadmin/owner | Visualiza responsables |
| Crear equipos y asignar capitán | Sí, gestor autorizado | Visualiza equipos |
| Invitar y gestionar plantillas | Sí, superadmin/creador/gestor con permiso; capitán aún no en web | Visualización de plantillas y respuestas de invitación; la gestión transaccional del capitán queda para la fase móvil |
| Generar fixture y configurar ida/vuelta | Sí, gestor autorizado | Visualiza jornadas, rondas y llaves |
| Elegir sede/cancha y horario | Sí, por partido y jornada | Visualiza hora de inicio/fin y cancha |
| Registrar acta, goles y asistencias | Sí, gestor autorizado | Visualiza marcador y eventos |
| Tabla, estadísticas y pichanga vinculada | Sí y API | Sí, navegación completa de lectura |

Así se cierra el módulo de campeonato en la app como experiencia de consulta,
seguimiento e invitaciones, y se cierra la operación completa en la web. La
creación/transacción desde app queda identificada como una fase posterior, no
como una funcionalidad implícitamente disponible.

## Reglas objetivo del dominio

- Actualmente solo el superadmin puede crear un campeonato desde la web.
- El superadmin puede delegar gestores del campeonato.
- El superadmin, los gestores y los capitanes podrán gestionar plantillas e
  invitar jugadores para cada campeonato cuando se habilite la fase móvil
  transaccional.
- El capitán administrará su equipo, pero el creador y los gestores conservarán
  la autoridad final para aprobar, retirar o mover jugadores.
- La plantilla puede ser mayor que la capacidad de un partido. Por ejemplo,
  un equipo 7 vs 7 puede tener 10 o más jugadores.
- Cada partido se representa como una pichanga vinculada al campeonato.
- Cada partido se juega en una cancha concreta de un polideportivo.
- Cada fecha/jornada tiene hora de inicio y hora de fin; además cada partido
  conserva su horario, duración y cancha.
- Una liga puede tener una sola vuelta o ida y vuelta. En ida y vuelta dos
  equipos se enfrentan dos veces, con localía diferenciada cuando sea posible.
- El creador configura los puntos por victoria, empate y derrota.
- El desempate es: puntos, diferencia de goles, goles a favor y, si todo sigue
  igual, decisión manual del creador con comentario obligatorio.
- La web administra actas y resultados oficiales; la app muestra el campeonato,
  tabla, fixture y eventos en vivo.

## Flujo de creación web

El backoffice ofrecerá un wizard:

1. **Información:** nombre, descripción, logo, reglamento y fechas.
2. **Visibilidad:** público, privado o solo con enlace.
3. **Formato:** liga, ida simple, ida y vuelta, llaves o híbrido (liga +
   playoffs en una fase posterior).
4. **Reglas:** puntos por victoria/empate/derrota, cantidad de equipos,
   jugadores por partido y reglas de desempate.
5. **Equipos:** nombre, color, logo y capitán.
6. **Gestores:** usuarios con permisos de plantillas, fixture, actas o
   administración completa.
7. **Plantillas:** invitaciones por nickname o enlace, aprobación y cierre de
   inscripción.
8. **Fixture:** generación automática, revisión manual y asignación de cancha,
   fecha, hora de inicio y hora de fin.
9. **Publicación:** publicación del campeonato y notificación a los afectados.

## Equipos, plantillas y convocatorias

Los equipos del campeonato son independientes de los grupos de Fulbii. Un
campeonato puede estar asociado a un grupo como audiencia, pero la plantilla
del torneo se gestiona de forma propia.

El capitán, un gestor o el superadmin puede:

- invitar por nickname;
- compartir un enlace de invitación;
- aceptar o rechazar solicitudes;
- cambiar la plantilla antes del cierre;
- convocar jugadores para una fecha;
- hacer sustituciones durante el partido;
- retirar o reemplazar jugadores con registro de auditoría.

Una plantilla amplia se separa de la convocatoria de cada partido:

- titular;
- suplente;
- convocado;
- jugó;
- no participó.

Los partidos jugados y las estadísticas se calculan a partir de los jugadores
que efectivamente participaron en la convocatoria, no de toda la plantilla.

## Fixture y sedes

El generador de liga usa un calendario round-robin:

- todos contra todos;
- una fecha libre si el número de equipos es impar;
- ida simple o ida y vuelta según configuración;
- sin duplicar enfrentamientos;
- edición manual antes de iniciar la jornada;
- bloqueo de regeneración después de publicar o iniciar partidos.

Una jornada contiene:

- número y nombre;
- fecha;
- hora de inicio;
- hora de fin;
- partidos programados;
- estado de la jornada.

El rango de la jornada es obligatorio para operar el calendario: `starts_at`
marca el inicio de la fecha y `ends_at` su cierre. Cada partido puede tener un
intervalo más corto dentro de ese rango, lo que permite encadenar varios
partidos en la misma sede.

Cada partido contiene:

- equipo local y visitante;
- cancha y polideportivo;
- inicio y fin;
- duración;
- pichanga vinculada;
- estado y acta.

Los campeonatos abiertos pueden usar sedes de cualquier polideportivo
disponible. La cancha se selecciona antes de publicar cada partido y se
conservan el `field_id` y `cancha_id` reales.

## Actas, goles y estadísticas

Los gestores autorizados registran desde web:

- marcador local/visitante;
- minuto y autor de cada gol;
- asistencia;
- gol en propia puerta;
- tarjetas;
- sustituciones;
- observaciones;
- confirmación del resultado.

El partido puede estar programado, en curso, pendiente de acta, finalizado,
reprogramado, suspendido o cancelado.

La tabla muestra:

| Pos | Equipo | PJ | PG | PE | PP | GF | GC | DG | Pts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

Las estadísticas de jugador incluyen partidos jugados, minutos, goles,
asistencias, tarjetas y promedio de calificaciones. Para arqueros se añaden
goles recibidos y vallas invictas. Los goles en contra son una estadística de
equipo; en el perfil individual solo se muestran como goles recibidos del
arquero cuando corresponda.

Las calificaciones del partido reutilizan la fórmula central de
`CombinedSkillRatingService` y las restricciones actuales: solo jugadores que
participaron, sin autocalificación y sin repetir la misma valoración.

## Experiencia en la app

Se añadirá **Campeonatos** dentro de Pichangas.

El detalle tendrá estas pestañas:

- **Resumen:** estado, siguiente partido, equipo propio y últimos resultados.
- **Tabla:** clasificación y desempates, resaltando el equipo propio.
- **Fixture:** jornadas, horarios, cancha y acceso a la pichanga.
- **En vivo:** marcador, goles, asistencias, tarjetas y cambios.
- **Equipos:** capitanes, plantillas y convocatorias.
- **Estadísticas:** goleadores, asistidores, arqueros y promedios.

La actualización en vivo usará refresco periódico, actualización manual y push
para eventos relevantes. Las notificaciones abrirán directamente el
campeonato, la jornada, el partido, la pichanga, la invitación o el acta.

## Permisos

Permisos separados por campeonato:

- `manage_settings`;
- `manage_teams`;
- `manage_rosters`;
- `manage_fixture`;
- `manage_match_live`;
- `manage_match_results`;
- `manage_admins`.

El superadmin conserva acceso total. Los gestores reciben permisos explícitos.
Los capitanes gestionarán la plantilla e invitaciones de su equipo en la fase
móvil transaccional, sujetos a la aprobación y corrección del creador o
gestores. En la entrega actual no hay acciones de capitán en el backoffice web
ni mutaciones de plantillas desde la app; solo lectura y respuesta de
invitaciones.

## Modelo técnico inicial

Se crearán tablas aditivas para campeonatos, gestores, equipos, miembros,
invitaciones, jornadas, partidos, convocatorias, eventos, sustituciones,
auditoría de resultados y estadísticas de jugador.

`group_pichangas` recibirá `championship_id` y `championship_match_id`.
También se ampliará `match_context` con `championship`; en ese contexto
`club_id` podrá ser nulo para campeonatos abiertos, mientras que las pichangas
normales de grupos conservarán su grupo obligatorio.

## Fases de implementación

### Fase 1: base y operación web (implementada)

- migraciones y modelos;
- creación de campeonato por superadmin;
- equipos, capitanes y gestores;
- invitaciones y plantillas;
- ida simple/ida y vuelta;
- generación y edición de fixture;
- asociación de cancha, horario y pichanga;
- tabla por puntos;
- llaves de eliminación de 2/4/8/16/32 equipos y avance del ganador;
- API de lectura e invitaciones para Flutter;
- web de publicación, plantillas, jornadas, sedes, actas y auditoría.

### Fase 2: experiencia móvil transaccional y vivo (diferida)

- crear/configurar campeonato desde app;
- inscripción y solicitudes públicas desde app;
- edición de fixture, sede y horario desde app;
- acta visual con goles, asistencias, tarjetas y sustituciones;
- marcador en vivo y presencia;
- resolución guiada de penales/desempates.

### Fase 3: comunidad y continuidad

- gestión de convocatorias desde app para capitanes;
- solicitudes públicas y enlaces privados;
- historial de campeonatos en perfiles;
- compartir tabla y resultados;
- exportación de estadísticas.

### Fase 4: playoffs híbridos

- liga + playoffs con clasificación configurable;
- prórroga y penales;
- reglas específicas por ronda.

## Criterios de aceptación

- Un superadmin crea una liga con ida simple o ida y vuelta.
- Un superadmin puede crear un campeonato por llaves con número de equipos potencia de dos y el ganador avanza al siguiente partido.
- Puede crear equipos, asignar capitanes y delegar gestores.
- Superadmin, gestores y capitanes pueden invitar y administrar plantillas con
  permisos claros.
- Cada jornada tiene rango horario y cada partido tiene cancha, inicio y fin.
- El fixture no duplica enfrentamientos y puede revisarse antes de publicar.
- Cada partido aparece como pichanga vinculada.
- Un acta confirmada actualiza puntos, GF, GC, DG y estadísticas de jugadores.
- La app muestra tabla, fixture, marcador, goles y asistencias.
- La app muestra invitaciones pendientes, plantillas y estadísticas derivadas, y abre el detalle de la pichanga vinculada.
- Los desempates respetan las reglas configuradas y la resolución manual queda
  auditada.
- Los cambios de plantilla, fixture y resultados generan notificaciones y
  trazabilidad.
