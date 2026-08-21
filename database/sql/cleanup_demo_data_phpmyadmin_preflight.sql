-- Fulbii cleanup preflight (read-only).
-- Run this file from phpMyAdmin before importing
-- cleanup_demo_data_phpmyadmin.sql.
-- The query must return ZERO rows. If it lists a table, stop and do not run
-- the cleanup file: share the output so the cleanup can be adapted safely.

SELECT expected.table_name AS missing_table
FROM (
    SELECT 'club_challenge_messages' AS table_name UNION ALL
    SELECT 'club_challenge_configurations' UNION ALL
    SELECT 'club_challenge_time_options' UNION ALL
    SELECT 'club_challenge_field_options' UNION ALL
    SELECT 'user_chat_presence' UNION ALL
    SELECT 'club_challenges' UNION ALL
    SELECT 'club_group_message_reads' UNION ALL
    SELECT 'club_group_messages' UNION ALL
    SELECT 'club_admin_activities' UNION ALL
    SELECT 'watch_position_samples' UNION ALL
    SELECT 'watch_match_events' UNION ALL
    SELECT 'watch_match_sessions' UNION ALL
    SELECT 'group_pichanga_waitlist' UNION ALL
    SELECT 'group_pichanga_notification_batches' UNION ALL
    SELECT 'group_pichanga_external_requests' UNION ALL
    SELECT 'group_pichanga_ratings' UNION ALL
    SELECT 'group_pichanga_comments' UNION ALL
    SELECT 'group_pichanga_posts' UNION ALL
    SELECT 'group_pichanga_participants' UNION ALL
    SELECT 'group_pichangas' UNION ALL
    SELECT 'historial_calificacion' UNION ALL
    SELECT 'calificaciones' UNION ALL
    SELECT 'user_profile_clips' UNION ALL
    SELECT 'goles' UNION ALL
    SELECT 'pichanga' UNION ALL
    SELECT 'evento_usuarios' UNION ALL
    SELECT 'evento' UNION ALL
    SELECT 'equipos' UNION ALL
    SELECT 'posicion' UNION ALL
    SELECT 'formacion' UNION ALL
    SELECT 'club_invitations' UNION ALL
    SELECT 'club_join_requests' UNION ALL
    SELECT 'club_notification_categories' UNION ALL
    SELECT 'user_group_notification_prefs' UNION ALL
    SELECT 'club_user' UNION ALL
    SELECT 'clubs' UNION ALL
    SELECT 'field_submission_photos' UNION ALL
    SELECT 'field_submissions' UNION ALL
    SELECT 'user_favorite_fields' UNION ALL
    SELECT 'field_geometries' UNION ALL
    SELECT 'servicio_polideportivo_detalle' UNION ALL
    SELECT 'horario_atencion' UNION ALL
    SELECT 'cancha' UNION ALL
    SELECT 'polideportivo' UNION ALL
    SELECT 'push_dispatch_logs' UNION ALL
    SELECT 'push_notifications' UNION ALL
    SELECT 'reports' UNION ALL
    SELECT 'strikes' UNION ALL
    SELECT 'user_blocks' UNION ALL
    SELECT 'product_events' UNION ALL
    SELECT 'failed_jobs' UNION ALL
    SELECT 'personal_access_tokens' UNION ALL
    SELECT 'user_devices' UNION ALL
    SELECT 'user_perfil' UNION ALL
    SELECT 'password_resets' UNION ALL
    SELECT 'users'
) AS expected
LEFT JOIN information_schema.tables AS actual
    ON actual.table_schema = DATABASE()
   AND actual.table_name = expected.table_name
WHERE actual.table_name IS NULL
ORDER BY expected.table_name;

SELECT
    COUNT(*) AS users_total,
    SUM(id IN (1,38,83,84,85)) AS protected_users,
    SUM(id NOT IN (1,38,83,84,85)) AS users_to_remove
FROM users;
