# 11. Ratings 1-10 + Clips de Perfil (Estado y QA)

> **Histórico / supersedido.** La escala vigente es `0.0–5.0` con estrellas
> nativas; no usar esta guía para validaciones ni sliders. Ver
> [AI_HANDOFF_CURRENT_STATE](AI_HANDOFF_CURRENT_STATE.md) y
> [API social](api/v1_pichanga_social.md). La información de clips sigue siendo
> contexto histórico.

## Estado del bloque
- ✅ Backend validaciones skills migradas a escala `1-10`.
- ✅ Regla de calificación libre cambiada a `1 vez por semana ISO` por par y club.
- ✅ Calificación por pichanga se mantiene independiente (1 por partido por par).
- ✅ Filtros de audiencia usan promedio combinado (libre + pichanga).
- ✅ API de clips de perfil creada:
  - `GET /api/v1/me/profile-clips`
  - `POST /api/v1/me/profile-clips`
  - `DELETE /api/v1/me/profile-clips/{clip}`
  - `PUT /api/v1/me/profile-clips/reorder`
  - `GET /api/v1/users/{user}/profile-clips`
- ✅ Flutter actualizado:
  - diálogo de rating en pichanga con `1-10`,
  - sección de clips en perfil (listar/subir/eliminar/reordenar).
- ✅ API de clips valida `source_duration_ms <= 20000` y tamaño de archivo hasta `20MB`.
- ⏳ Editor local completo (recorte cuadrado + selección exacta 7s + transcode loop) pendiente.
- ⏳ Exportación GIF y sticker pack WhatsApp pendiente.

## SQL a ejecutar (una vez en la BD activa)
1. Ejecuta:
   - `database/sql/fulbii_upgrade_2026_03_29_ratings10_profile_clips.sql`
2. Verifica tabla:
```sql
SHOW CREATE TABLE user_profile_clips;
```
3. Verifica vistas:
```sql
SHOW FULL TABLES WHERE Table_type = 'VIEW' AND Tables_in_fulbii LIKE 'vw_skill_ratings_%';
```

## QA funcional recomendado
1. **Ratings 1-10**
   - En pichanga, abrir “Calificar jugador”.
   - Verificar sliders del `1` al `10`.
   - Enviar rating y confirmar `200`.
2. **Regla semanal libre**
   - Calificar al mismo usuario dos veces en la misma semana.
   - Esperado: segunda bloqueada con mensaje semanal.
3. **Clips perfil**
   - Subir MP4 <= 20s desde perfil.
   - Ver preview en lista.
   - Reordenar (subir/bajar) y validar orden persistente.
   - Eliminar clip y validar que desaparece.
4. **Límite de clips**
   - Subir 6 clips.
   - Esperado: rechazo al 6to con “Máximo 5 clips activos”.

## Notas de alcance del bloque actual
- En esta versión, el clip se sube como MP4 final desde dispositivo.
- La etapa de edición avanzada (crop cuadrado + trim exacto a 7s + GIF/sticker) entra como siguiente bloque para no romper estabilidad de release actual.
