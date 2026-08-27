@extends('public.layout')

@section('title', 'Centro de soporte')
@section('meta_description', 'Obtén ayuda con tu cuenta, canchas, pichangas, grupos, retos y notificaciones de Fulbii.')

@section('content')
  <div class="intro">
    <p class="eyebrow">Estamos para ayudarte</p>
    <h1>Centro de soporte Fulbii</h1>
    <p class="lead">¿Tu próxima pichanga no salió como esperabas? Cuéntanos qué ocurrió y te ayudaremos a resolverlo.</p>
  </div>

  <div class="content-grid">
    <section class="panel" aria-labelledby="faq-title">
      <h2 id="faq-title">Preguntas frecuentes</h2>
      <div class="faq">
        <details open>
          <summary>No puedo iniciar sesión</summary>
          <p>Confirma que estás usando el mismo correo o proveedor con el que te registraste. Si el problema continúa, escríbenos indicando tu correo, dispositivo y una captura del mensaje que aparece.</p>
        </details>
        <details>
          <summary>¿Cómo encuentro una cancha o una pichanga?</summary>
          <p>En el mapa puedes cambiar entre mapa y lista, aplicar filtros por horario, formato, superficie y precio, y abrir el detalle de cada polideportivo o pichanga.</p>
        </details>
        <details>
          <summary>¿Cómo confirmo mi asistencia?</summary>
          <p>Abre el detalle de la pichanga y utiliza la acción de asistencia. El estado se refleja en tu agenda, en el grupo y en las notificaciones correspondientes.</p>
        </details>
        <details>
          <summary>¿Cómo funcionan los grupos, retos y campeonatos?</summary>
          <p>Los grupos organizan a sus integrantes y partidos. Los retos permiten coordinar enfrentamientos entre grupos y los campeonatos muestran equipos, fixture, tabla, resultados y estadísticas.</p>
        </details>
        <details>
          <summary>No recibo notificaciones push</summary>
          <p>Revisa que las notificaciones estén permitidas en tu dispositivo y que Fulbii tenga conexión. Algunas preferencias permiten silenciar categorías o grupos. Si ves la notificación dentro de la app pero no como alerta del sistema, envíanos el modelo del dispositivo, la versión de iOS o Android y la hora aproximada del evento.</p>
        </details>
        <details>
          <summary>¿Cómo reporto o bloqueo a un usuario?</summary>
          <p>Desde el perfil, publicación o mensaje correspondiente puedes reportar contenido. También puedes bloquear a un usuario. Los reportes se revisan mediante las herramientas de moderación de Fulbii.</p>
        </details>
        <details>
          <summary>Quiero aportar una cancha</summary>
          <p>Utiliza la sección de aportes de canchas. Las solicitudes tienen límites para cuentas normales y pasan por revisión. Los cambios de estado se comunican mediante la bandeja y las notificaciones.</p>
        </details>
        <details>
          <summary>¿Cómo solicito eliminar mi cuenta?</summary>
          <p>Escríbenos desde el correo asociado a tu cuenta. Verificaremos la solicitud y te informaremos qué datos se eliminarán o conservarán cuando exista una obligación legal o de seguridad.</p>
        </details>
        <details>
          <summary>¿Puedo usar Fulbii con Apple Watch?</summary>
          <p>Cuando la función esté disponible para tu versión, necesitarás conceder los permisos de actividad y ubicación solicitados por watchOS. Si una sesión no se sincroniza, indica el modelo del reloj, la versión de watchOS y la hora de la sesión.</p>
        </details>
      </div>

      <div class="note">Por seguridad, nunca envíes contraseñas, tokens de acceso, claves privadas de Firebase ni códigos de verificación.</div>
    </section>

    <aside class="side">
      <div class="contact-card">
        <h2>Hablemos</h2>
        <p>La vía más rápida para resolver dudas es WhatsApp. También puedes escribirnos por email.</p>
        <div class="contact-actions">
          <a class="button" href="{{ $supportWhatsappUrl }}" target="_blank" rel="noopener">Escribir por WhatsApp</a>
          <a class="button secondary" href="mailto:{{ $supportEmail }}">{{ $supportEmail }}</a>
        </div>
      </div>
      <div class="panel" style="margin-top:14px">
        <h2>Para ayudarnos a ayudarte</h2>
        <p>Incluye:</p>
        <ul>
          <li>Tu nickname o correo.</li>
          <li>Modelo y sistema operativo.</li>
          <li>Versión de Fulbii.</li>
          <li>Fecha y hora del problema.</li>
          <li>Captura o pasos para reproducirlo.</li>
        </ul>
      </div>
    </aside>
  </div>
@endsection
