@extends('public.layout')

@section('title', 'Política de privacidad')
@section('meta_description', 'Conoce cómo Fulbii trata tus datos, contenido, ubicación, notificaciones y actividad deportiva.')

@section('content')
  <div class="intro">
    <p class="eyebrow">Transparencia primero</p>
    <h1>Política de privacidad</h1>
    <p class="lead">En Fulbii usamos tus datos para ayudarte a encontrar dónde jugar, coordinar mejor y mantener una comunidad segura.</p>
    <div class="legal-meta"><span class="meta-pill">Responsable: {{ $legalOwner }}</span><span class="meta-pill">Vigente desde: {{ $privacyEffectiveDate }}</span></div>
  </div>

  <div class="content-grid">
    <article class="panel" aria-label="Política de privacidad de Fulbii">
      <h2>1. Alcance</h2>
      <p>Esta política explica qué información recopilamos cuando utilizas Fulbii, cómo la usamos, con quién puede compartirse y qué opciones tienes para controlarla. Aplica a la aplicación móvil, sus funciones compatibles con Apple Watch y las páginas públicas de fulbii.com.</p>

      <h3>2. Información que recopilamos</h3>
      <ul>
        <li><strong>Cuenta e identidad:</strong> nombre, correo electrónico, nickname, identificadores de Google o Apple y datos necesarios para iniciar sesión.</li>
        <li><strong>Perfil deportivo:</strong> sexo, fecha de nacimiento, altura, avatar, habilidades, posición sugerida, calificaciones y rankings.</li>
        <li><strong>Ubicación:</strong> ubicación aproximada o precisa, cuando concedes permiso, para mostrar canchas cercanas y habilitar funciones deportivas.</li>
        <li><strong>Contenido:</strong> fotos de perfil, clips, fotos de canchas y polideportivos, publicaciones, comentarios, mensajes, reportes y contenido de campeonatos.</li>
        <li><strong>Dispositivo y notificaciones:</strong> identificadores técnicos, token de notificaciones, sistema operativo, versión de la app y datos necesarios para entregar alertas.</li>
        <li><strong>Actividad Watch:</strong> sesiones deportivas, ubicación, distancia, velocidad u otros datos autorizados por ti cuando utilizas las funciones compatibles con Apple Watch.</li>
        <li><strong>Soporte y seguridad:</strong> información que nos entregas al contactar soporte, registros de errores y datos necesarios para investigar abusos o incidentes.</li>
      </ul>

      <h3>3. Para qué usamos la información</h3>
      <ul>
        <li>Crear y mantener tu cuenta y completar el onboarding.</li>
        <li>Mostrar canchas, pichangas, grupos, retos y campeonatos.</li>
        <li>Gestionar confirmaciones, cupos, listas de espera, equipos y formaciones.</li>
        <li>Calcular habilidades, promedios, posiciones sugeridas y rankings.</li>
        <li>Enviar notificaciones sobre actividad relevante, chats, invitaciones y cambios.</li>
        <li>Prevenir fraude, abuso, spam y contenido que infrinja las reglas.</li>
        <li>Atender solicitudes de soporte, medir fallos y mejorar la estabilidad.</li>
      </ul>

      <h3>4. Servicios y proveedores</h3>
      <p>Fulbii puede apoyarse en proveedores que procesan información en nuestro nombre: Google y Apple para autenticación, Firebase Cloud Messaging para notificaciones, Google Maps y servicios de ubicación para mapas, y proveedores de hosting, almacenamiento y correo. Estos servicios reciben únicamente la información necesaria para prestar su función y se rigen por sus propias políticas.</p>

      <h3>5. Contenido público y comunidad</h3>
      <p>Los perfiles, nicknames, calificaciones, publicaciones, grupos y ciertos datos de actividad pueden ser visibles para otros usuarios según tus controles de visibilidad. El contenido de usuarios puede ser reportado, bloqueado, moderado o retirado cuando incumpla las reglas de la comunidad.</p>

      <h3>6. Ubicación y permisos</h3>
      <p>Puedes retirar el permiso de ubicación, cámara, fotos, notificaciones o HealthKit desde la configuración de tu dispositivo. Algunas funciones dejarán de estar disponibles si retiras un permiso necesario.</p>

      <h3>7. Conservación y eliminación</h3>
      <p>Conservamos la información mientras sea necesaria para prestar el servicio, cumplir obligaciones legales, resolver disputas, mantener la seguridad o proteger la integridad de los registros deportivos. Para solicitar la eliminación de tu cuenta y datos asociados, contacta a <a href="mailto:{{ $supportEmail }}">{{ $supportEmail }}</a> o por <a href="{{ $supportWhatsappUrl }}" target="_blank" rel="noopener">WhatsApp</a>. Te pediremos verificar que eres el titular de la cuenta.</p>

      <h3>8. Seguridad</h3>
      <p>Usamos HTTPS, controles de acceso, autenticación y medidas de protección razonables para resguardar la información. Ningún sistema conectado a internet puede garantizar seguridad absoluta.</p>

      <h3>9. Menores de edad</h3>
      <p>Fulbii no está dirigida a niños pequeños. Si un padre, madre o tutor considera que un menor nos entregó datos sin autorización, puede contactarnos para solicitar su revisión y eliminación cuando corresponda.</p>

      <h3>10. Tus derechos y contacto</h3>
      <p>Puedes solicitar acceso, corrección, actualización o eliminación de tus datos, además de retirar permisos del dispositivo. Para ejercer tus derechos, escribe a <a href="mailto:{{ $supportEmail }}">{{ $supportEmail }}</a> o utiliza el canal de <a href="{{ $supportWhatsappUrl }}" target="_blank" rel="noopener">WhatsApp de soporte</a>.</p>

      <h3>11. Cambios a esta política</h3>
      <p>Podemos actualizar esta política cuando cambien la plataforma, los proveedores o las obligaciones aplicables. Publicaremos la versión vigente en esta página e indicaremos su fecha de actualización.</p>

      <div class="note">Esta página es información pública de privacidad del producto. Si necesitas una aclaración sobre un caso concreto, contáctanos antes de compartir información sensible.</div>
    </article>

    <aside class="side">
      <div class="contact-card">
        <h2>¿Tienes una consulta?</h2>
        <p>Estamos disponibles para aclarar cómo tratamos tus datos.</p>
        <div class="contact-actions">
          <a class="button" href="mailto:{{ $supportEmail }}">Escribir por email</a>
          <a class="button secondary" href="{{ $supportWhatsappUrl }}" target="_blank" rel="noopener">WhatsApp</a>
        </div>
      </div>
      <div class="panel" style="margin-top:14px">
        <h2>Controles rápidos</h2>
        <p>Desde la app puedes administrar permisos del dispositivo, preferencias de notificaciones, visibilidad, bloqueos y reportes.</p>
        <p><a href="{{ route('support') }}">Visitar el centro de soporte →</a></p>
      </div>
    </aside>
  </div>
@endsection
