# QA móvil — Cambios del 6 al 10 de agosto de 2026

## Preparación

- **Cuenta A:** admin de al menos un grupo, con una pichanga futura y un
  polideportivo disponible.
- **Cuenta B:** miembro del mismo grupo; usar un segundo dispositivo físico.
- **Cuenta C:** no miembro para descubrir grupos, recibir invitación y hacer
  solicitud externa cuando corresponda.
- Tener una pichanga llena para lista de espera, una pasada para comprobar que
  no se ofrece como abierta, fotos de cancha/polideportivo y un usuario con
  fecha de nacimiento para ranking por edad.
- iOS y Android con permiso de notificaciones aceptado; para iOS probar una
  build TestFlight, no solo el simulador.

Marcar cada caso como `OK`, `Falla`, `No aplica` y adjuntar captura/log cuando
falle. Toda creación o cambio que notifique debe verificarse en bandeja y push.

## 1. Mapa, canchas y polideportivos

| Caso | Acción | Resultado esperado |
| --- | --- | --- |
| Filtros | Abrir filtros y elegir Hoy, Hoy y mañana y rango propio. | Los tres controles permanecen en una fila y aplican el mismo filtro. |
| Viewport | Hacer zoom, pan rápido y volver a una zona reciente. | Se ven marcadores previos mientras carga; no hay vacío prolongado ni duplicados. |
| Clusters | Alejar/acercar entre grupos de recintos. | Cluster y marcadores representan la zona visible correctamente. |
| Preview | Tocar un polideportivo con varias canchas y fotos. | No aparece título `Canchas`; tarjetas compactas, foto lateral y formato `N vs N`. |
| Carrusel | Tocar una pichanga de Hoy y otra de Mañana. | Badge rojo/naranja pulsante, tarjeta centrada, mapa enfoca el recinto y marcador pulsa rojo. |
| Detalle | Abrir un polideportivo. | Solo pichangas abiertas futuras; cada tarjeta navega al detalle correcto. |

## 2. Aportes de canchas

- Enviar una solicitud; revisar fotos, dirección, WhatsApp y galería.
- Con una pendiente, intentar iniciar otra: debe aparecer bloqueo y datos de
  la solicitud existente.
- Resolver la solicitud desde backoffice; la Cuenta A recibe bandeja/push y
  navega al aporte o contenido creado.
- Crear tres solicitudes en el mismo mes y comprobar que la cuarta es rechazada
  aunque las anteriores estén aprobadas o rechazadas.
- Comprobar el sello `Aportado por @usuario` en detalle de cancha o
  polideportivo aprobado, nunca en el mapa.

## 3. Grupos, administración y comunidad

- Revisar Mis grupos: logo lateral grande, `X pichangas`, `Asistiré a X` en la
  misma fila; no mostrar `visible` ni `miembro`.
- Revisar Descubrir: logo lateral, pichangas abiertas, tarjeta navegable y sin
  botón Solicitar ni texto visible.
- Confirmar una pichanga del grupo y comprobar badge `Asistiré` en lista y
  calendario de su detalle.
- Promover a Cuenta B como admin, degradarla, retirarla y confirmar que no se
  puede retirar al último admin.
- Invitar a Cuenta C, revocar/responder invitación y validar notificaciones y
  navegación desde bandeja.
- Cambiar `Permitir que los miembros creen pichangas`; confirmar selector y
  backend con Cuenta B en ambos modos.
- Enviar/leer chat general, silenciar grupo/categoría, reportar mensaje y
  bloquear jugador. Verificar exclusiones de avisos.

## 4. Crear pichanga, agenda y espera

- Abrir Crear desde polideportivo y desde grupo: seleccionar grupo permitido,
  verificar grupos Solo administradores deshabilitados y cancha real sin ID
  manual.
- Revisar valores iniciales: Versus, 7 vs 7, 1 hora y siguiente media hora.
- Activar/desactivar descripción; apagada no debe enviar texto.
- Elegir cada duración, Personalizar, hora `:00`, `:30` y selector nativo.
- Comprobar que jugadores por equipo y duración no se desbordan en iPhone
  compacto.
- En calendario, validar anillos verde/naranja/mixto/gris y etiquetas
  `No confirmada` / `Asistencia confirmada`.
- Llenar pichanga; entrar/salir de lista de espera y liberar cupo. Debe
  promoverse el primer elegible y notificarlo.

## 5. Detalle de pichanga y retos

- Mover jugadores entre equipos cuando el permiso lo permita; abrir cancha de
  formación, arrastrar fichas dentro de límites y guardar posiciones.
- Publicar, comentar, borrar permitido y reportar post/comentario. No debe
  aparecer pantalla roja Flutter.
- Calificar desde actividad: solo confirmados, sin autoevaluación ni segundo
  voto del mismo par/pichanga.
- Crear reto: fotos de ambos grupos, vigencia, propuesta de cancha y fecha/hora
  visibles, configuraciones y chat contextual.
- Probar notificación de reto, propuesta y mensaje en Cuenta A/B; al tocarla
  debe abrir el reto correcto.

## 6. Perfil, calificaciones y rankings

- Abrir perfil propio y público desde el círculo de puntaje sin error 500.
- Calificar a compañero compartido: una vez por semana ISO global, incluso si
  comparte varios grupos.
- Confirmar orden visual: Delantero, Mediocampo, Defensa, Arquero azul/turquesa
  y Físico ámbar; cada control muestra número e icono.
- Mover sliders: se actualizan promedio jugador, arquero, principal y posición
  sugerida. Revisar disclaimer.
- Ver historial de calificaciones con evaluador, fecha, comentario y desglose.
- Validar fórmula con datos conocidos: campo = D/M/Def; jugador = campo/físico;
  arquero = arquero/físico; principal = mayor.
- Abrir Ranking: Total primero, bandas que tengan usuarios, usuario propio
  resaltado, sin votos al final por nickname.

## 7. Notificaciones y plataforma

- Crear pichanga, solicitar ingreso, decidir solicitud, invitar, calificar,
  enviar chat, crear reto, cambiar fecha/cancha, cancelar y promover espera.
- Para cada evento: validar badge, bandeja, foto/fallback, texto, push y deep
  link. Confirmar que el emisor, grupos silenciados y chat activo se excluyen
  cuando corresponde.
- Repetir en iOS: app abierta, background y terminada; revisar imagen rica si
  el payload la ofrece. Repetir en Android con comportamiento estándar.
- Rotar dispositivo: la aplicación mantiene orientación vertical.
- Probar snackbars informativos, éxito y error; deben ser verde bosque o rojo
  sobrio, nunca amarillos/blanquecinos.
- Probar cámara y galería en simulador/dispositivo sin bloqueos.

## Cierre de QA

1. Ejecutar `php artisan push:verification-report --minutes=30` en VPS tras
   pruebas push y adjuntar su salida.
2. Confirmar `systemctl status fulbii-queue` activo.
3. Registrar build iOS/Android, dispositivos, cuentas y hallazgos en la tarea
   de release antes de publicar.
