# Fulbii — Contenido y estructura de landing

## Objetivo

Convertir visitas web en aperturas de app, instalaciones y retorno a enlaces
compartidos, sin intentar replicar el producto móvil en navegador.

## Mensaje central

**Titular:** Juega más. Coordina mejor.

**Subtítulo:** Fulbii reúne canchas, pichangas, grupos, retos y tu perfil
futbolero en una sola app.

**Propuesta de valor:** Menos mensajes dispersos, más partidos confirmados.

## Secciones de la landing

1. **Hero:** mensaje central, abrir app, descarga iPhone/Android y vista previa
   de marca.
2. **Problema/solución:** organizar fútbol amateur no debería depender de
   chats, capturas y listas manuales.
3. **Funciones:** canchas, pichangas, grupos, retos, rankings y Watch.
4. **Cómo funciona:** descubre, coordina y evoluciona en tres pasos.
5. **Confianza/comunidad:** asistencia, permisos, avisos y moderación.
6. **CTA final:** abrir Fulbii o descargar desde la tienda disponible.
7. **Footer:** administración, privacidad, términos y soporte cuando estén
   publicados.

## CTAs aprobados

- Principal: `Abrir Fulbii` → `fulbii://pichangas`.
- iOS: `Descargar en iPhone` → `IOS_STORE_URL`.
- Android: `Descargar en Android` → `ANDROID_STORE_URL`.
- En deep links: `Abrir Fulbii`, acompañado por los mismos fallbacks de tienda.

No publicar botones de tienda con URLs inventadas. Mientras una URL no esté
configurada, el CTA de apertura de app se mantiene como principal.

## Enlaces compartibles

| Enlace web | Abre en app | Uso |
| --- | --- | --- |
| `/join/{code}` | `fulbii://join/{code}` | Invitación o solicitud a grupo. |
| `/club/{id}` | `fulbii://club/{id}` | Compartir un grupo. |
| `/pichanga/{id}` | `fulbii://pichanga/{id}` | Compartir una pichanga. |

Todos deben conservar página web visible, canonical URL, apertura diferida de
la app y fallback de descarga.

## Activos pendientes de producto

- Capturas reales de iOS y Android para hero y módulos.
- Logo/vector y guía de uso de marca final.
- Testimonios o métricas verificables; no inventar números de usuarios,
  partidos o canchas.
- Enlaces de privacidad, términos, soporte y tiendas productivas.
- Eventos de analítica: vista de landing, clic por CTA, apertura deep link y
  fallback de tienda.

## SEO y accesibilidad

- Español como idioma principal; títulos y meta descripción por página.
- Una sola jerarquía `h1`, contraste AA, botones con texto explícito y diseño
  responsive.
- Páginas de deep link con `noindex`; la landing sí es indexable.
- Incluir Open Graph cuando existan imágenes de campaña aprobadas.
