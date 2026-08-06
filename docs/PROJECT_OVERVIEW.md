# Fulbii 2 - Project Overview

## Objetivo
Ofrecer una experiencia deportiva social mobile-first que conecte organización de pichangas, interacción comunitaria y tracking wearable en un solo ecosistema.

## Perfiles de usuario
- Jugador/usuario app.
- Administrador staff/superadmin (backoffice).

## Procesos end-to-end (macro)
1. Login social + onboarding.
2. Descubrimiento de canchas, grupos y pichangas.
3. Coordinación social (retos, chat, notificaciones).
4. Tracking de sesiones en watch y sincronización con backend.
5. Operación administrativa y moderación desde backoffice.

## Funcionalidades vigentes
- API v1 amplia por dominio social/deportivo, con contratos públicos y
  autenticados documentados por módulo.
- App Flutter con mapa, grupos, agenda/calendario de pichangas, perfil y
  notificaciones.
- Grupos separados por membresía activa: `Mis grupos` y `Descubrir grupos` no
  se solapan.
- Pichangas con equipos persistentes, agenda, calendario, feed, solicitudes y
  detalle de recinto.
- Perfil deportivo público, clips y estrellas globales en escala 0.0–5.0.
- Módulo watch con sesiones/eventos/samples en batch.

## Canales
- App Flutter (mobile-first).
- Backoffice web.
- watchOS y Wear OS.

## MD actuales del proyecto (propios)
- `README.md`
- `docs/*.md` (operación, API, ADR, roadmap, QA/release)
- `fulbii_app/README.md`
- `fulbii_watchos/README.md`
- `fulbii_wearos/README.md`
- `docs/PROJECT_OVERVIEW.md`
- `docs/TECH_AUDIT.md`
- `docs/UX_UI_AUDIT.md`
- `docs/STATUS_GAPS.md`

No incluye MD de terceros/autogenerados.

## Fuente de verdad para continuidad

Consultar [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md) antes de
tomar decisiones de producto, contratos API o migraciones de datos.
