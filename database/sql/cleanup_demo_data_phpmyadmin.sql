-- Fulbii demo-data cleanup for phpMyAdmin: DESTRUCTIVE
--
-- This variant deliberately uses no CREATE/DROP PROCEDURE and no DELIMITER,
-- so it does not depend on MariaDB's mysql.proc metadata. Import this file
-- from phpMyAdmin's Import tab only after taking a database backup. Run the
-- matching cleanup_demo_data_phpmyadmin_preflight.sql first: it must return
-- no missing tables before this destructive file is imported.
--
-- Protected production users: 1, 38, 83, 84 and 85.
-- For local-only cleanup, change EVERY occurrence of (1,38,83,84,85) below
-- to (1,38) before importing.
--
-- IMPORTANT: this script targets the current Fulbii schema. Run
-- cleanup_demo_preview.sql first and verify the protected users exist.

START TRANSACTION;
SET FOREIGN_KEY_CHECKS = 0;

-- Challenges, chats and club activity.
DELETE FROM club_challenge_messages;
DELETE FROM club_challenge_configurations;
DELETE FROM club_challenge_time_options;
DELETE FROM club_challenge_field_options;
DELETE FROM user_chat_presence;
DELETE FROM club_challenges;
DELETE FROM club_group_message_reads;
DELETE FROM club_group_messages;
DELETE FROM club_admin_activities;

-- Pichangas, social activity, ratings and Watch.
DELETE FROM watch_position_samples;
DELETE FROM watch_match_events;
DELETE FROM watch_match_sessions;
DELETE FROM group_pichanga_waitlist;
DELETE FROM group_pichanga_notification_batches;
DELETE FROM group_pichanga_external_requests;
DELETE FROM group_pichanga_ratings;
DELETE FROM group_pichanga_comments;
DELETE FROM group_pichanga_posts;
DELETE FROM group_pichanga_participants;
DELETE FROM group_pichangas;
DELETE FROM historial_calificacion;
DELETE FROM calificaciones;
DELETE FROM user_profile_clips;

-- Legacy event/team activity.
DELETE FROM goles;
DELETE FROM pichanga;
DELETE FROM evento_usuarios;
DELETE FROM evento;
DELETE FROM equipos;
DELETE FROM posicion;
DELETE FROM formacion;

-- Groups, invitations and preferences.
DELETE FROM club_invitations;
DELETE FROM club_join_requests;
DELETE FROM club_notification_categories;
DELETE FROM user_group_notification_prefs;
DELETE FROM club_user;
DELETE FROM clubs;

-- Field submissions, media, courts and sports complexes.
DELETE FROM field_submission_photos;
DELETE FROM field_submissions;
DELETE FROM user_favorite_fields;
DELETE FROM field_geometries;
DELETE FROM servicio_polideportivo_detalle;
DELETE FROM horario_atencion;
DELETE FROM cancha;
DELETE FROM polideportivo;

-- Product, moderation and push history. Personal devices/tokens of the
-- protected accounts are kept below.
DELETE FROM push_dispatch_logs;
DELETE FROM push_notifications;
DELETE FROM reports;
DELETE FROM strikes;
DELETE FROM user_blocks;
DELETE FROM product_events;
DELETE FROM failed_jobs;

-- Remove dependent records belonging to accounts being removed.
DELETE FROM personal_access_tokens
WHERE tokenable_id NOT IN (1,38,83,84,85);
DELETE FROM user_devices
WHERE user_id NOT IN (1,38,83,84,85);
DELETE FROM user_perfil
WHERE id_user NOT IN (1,38,83,84,85);
DELETE FROM password_resets;

-- Finally remove all demo users while retaining the five real accounts.
DELETE FROM users
WHERE id NOT IN (1,38,83,84,85);

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;

SELECT
    'cleanup_complete' AS status,
    COUNT(*) AS users_remaining,
    SUM(id IN (1,38,83,84,85)) AS protected_users_remaining,
    SUM(id NOT IN (1,38,83,84,85)) AS unexpected_users_remaining
FROM users;

SELECT COUNT(*) AS polideportivos_remaining FROM polideportivo;
SELECT COUNT(*) AS canchas_remaining FROM cancha;
SELECT COUNT(*) AS clubs_remaining FROM clubs;
SELECT COUNT(*) AS pichangas_remaining FROM group_pichangas;
