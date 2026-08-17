-- Fulbii demo-data cleanup: DESTRUCTIVE
-- IMPORTANT: Export a phpMyAdmin backup first. Select the intended Fulbii
-- database before importing. Change the next value only when you deliberately
-- need a different environment-specific keep list (local: '1,38').
-- It intentionally keeps personal_access_tokens, user_devices and user settings
-- for the selected users, while removing all demo/product activity.

SET @fulbii_cleanup_keep_users = '1,38,83,84,85';

DROP PROCEDURE IF EXISTS fulbii_cleanup_delete_table;
DELIMITER $$
CREATE PROCEDURE fulbii_cleanup_delete_table(IN requested_table VARCHAR(64))
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = requested_table
    ) THEN
        SET @cleanup_sql = CONCAT('DELETE FROM `', REPLACE(requested_table, '`', '``'), '`');
        PREPARE cleanup_statement FROM @cleanup_sql;
        EXECUTE cleanup_statement;
        DEALLOCATE PREPARE cleanup_statement;
    END IF;
END$$

CREATE PROCEDURE fulbii_cleanup_delete_non_protected(IN requested_table VARCHAR(64), IN user_column VARCHAR(64))
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = requested_table
    ) THEN
        SET @cleanup_sql = CONCAT(
            'DELETE FROM `', REPLACE(requested_table, '`', '``'), '` WHERE `',
            REPLACE(user_column, '`', '``'), '` IS NOT NULL AND FIND_IN_SET(CAST(`',
            REPLACE(user_column, '`', '``'), '` AS CHAR), @fulbii_cleanup_keep_users) = 0'
        );
        PREPARE cleanup_statement FROM @cleanup_sql;
        EXECUTE cleanup_statement;
        DEALLOCATE PREPARE cleanup_statement;
    END IF;
END$$

CREATE PROCEDURE fulbii_cleanup_demo_data()
BEGIN
    DECLARE protected_count INT DEFAULT 0;
    DECLARE expected_count INT DEFAULT 0;

    SET expected_count = 1 + LENGTH(@fulbii_cleanup_keep_users)
        - LENGTH(REPLACE(@fulbii_cleanup_keep_users, ',', ''));
    SELECT COUNT(*) INTO protected_count FROM users
    WHERE FIND_IN_SET(CAST(id AS CHAR), @fulbii_cleanup_keep_users) > 0;
    IF protected_count <> expected_count THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CLEANUP ABORTED: one or more protected users were not found.';
    END IF;

    START TRANSACTION;
    SET FOREIGN_KEY_CHECKS = 0;

    -- Challenge and group-chat activity.
    CALL fulbii_cleanup_delete_table('club_challenge_messages');
    CALL fulbii_cleanup_delete_table('club_challenge_configurations');
    CALL fulbii_cleanup_delete_table('club_challenge_time_options');
    CALL fulbii_cleanup_delete_table('club_challenge_field_options');
    CALL fulbii_cleanup_delete_table('user_chat_presence');
    CALL fulbii_cleanup_delete_table('club_challenges');
    CALL fulbii_cleanup_delete_table('club_group_message_reads');
    CALL fulbii_cleanup_delete_table('club_group_messages');
    CALL fulbii_cleanup_delete_table('club_admin_activities');

    -- Pichanga, social, ratings and Watch activity.
    CALL fulbii_cleanup_delete_table('watch_position_samples');
    CALL fulbii_cleanup_delete_table('watch_match_events');
    CALL fulbii_cleanup_delete_table('watch_match_sessions');
    CALL fulbii_cleanup_delete_table('group_pichanga_waitlist');
    CALL fulbii_cleanup_delete_table('group_pichanga_notification_batches');
    CALL fulbii_cleanup_delete_table('group_pichanga_external_requests');
    CALL fulbii_cleanup_delete_table('group_pichanga_ratings');
    CALL fulbii_cleanup_delete_table('group_pichanga_comments');
    CALL fulbii_cleanup_delete_table('group_pichanga_posts');
    CALL fulbii_cleanup_delete_table('group_pichanga_participants');
    CALL fulbii_cleanup_delete_table('group_pichangas');
    CALL fulbii_cleanup_delete_table('historial_calificacion');
    CALL fulbii_cleanup_delete_table('calificaciones');
    CALL fulbii_cleanup_delete_table('user_profile_clips');

    -- Legacy event/team/pichanga activity, if present.
    CALL fulbii_cleanup_delete_table('goles');
    CALL fulbii_cleanup_delete_table('pichanga');
    CALL fulbii_cleanup_delete_table('evento_usuarios');
    CALL fulbii_cleanup_delete_table('evento');
    CALL fulbii_cleanup_delete_table('equipos');
    CALL fulbii_cleanup_delete_table('posicion');
    CALL fulbii_cleanup_delete_table('formacion');

    -- Groups and group-bound preferences.
    CALL fulbii_cleanup_delete_table('club_invitations');
    CALL fulbii_cleanup_delete_table('club_join_requests');
    CALL fulbii_cleanup_delete_table('club_notification_categories');
    CALL fulbii_cleanup_delete_table('user_group_notification_prefs');
    CALL fulbii_cleanup_delete_table('club_user');
    CALL fulbii_cleanup_delete_table('clubs');

    -- Field submissions, media and field/court data.
    CALL fulbii_cleanup_delete_table('field_submission_photos');
    CALL fulbii_cleanup_delete_table('field_submissions');
    CALL fulbii_cleanup_delete_table('user_favorite_fields');
    CALL fulbii_cleanup_delete_table('field_geometries');
    CALL fulbii_cleanup_delete_table('cancha_photos');
    CALL fulbii_cleanup_delete_table('polideportivo_photos');
    CALL fulbii_cleanup_delete_table('servicio_polideportivo_detalle');
    CALL fulbii_cleanup_delete_table('horario_atencion');
    CALL fulbii_cleanup_delete_table('cancha');
    CALL fulbii_cleanup_delete_table('polideportivo');

    -- Product/moderation/push activity. Devices and tokens of protected users remain.
    CALL fulbii_cleanup_delete_table('push_dispatch_logs');
    CALL fulbii_cleanup_delete_table('push_notifications');
    CALL fulbii_cleanup_delete_table('reports');
    CALL fulbii_cleanup_delete_table('strikes');
    CALL fulbii_cleanup_delete_table('user_blocks');
    CALL fulbii_cleanup_delete_table('product_events');
    CALL fulbii_cleanup_delete_table('failed_jobs');

    -- Remove dependent personal rows for fake accounts before deleting users.
    CALL fulbii_cleanup_delete_non_protected('personal_access_tokens', 'tokenable_id');
    CALL fulbii_cleanup_delete_non_protected('user_devices', 'user_id');
    CALL fulbii_cleanup_delete_non_protected('user_perfil', 'id_user');
    -- Password resets are temporary and are cleared to avoid leaving reset
    -- links for accounts that have just been removed.
    CALL fulbii_cleanup_delete_table('password_reset_tokens');
    CALL fulbii_cleanup_delete_table('password_resets');
    CALL fulbii_cleanup_delete_non_protected('users', 'id');

    SET FOREIGN_KEY_CHECKS = 1;
    COMMIT;

    SELECT 'cleanup_complete' AS status,
           (SELECT COUNT(*) FROM users WHERE FIND_IN_SET(CAST(id AS CHAR), @fulbii_cleanup_keep_users) > 0) AS protected_users_remaining,
           (SELECT COUNT(*) FROM users WHERE FIND_IN_SET(CAST(id AS CHAR), @fulbii_cleanup_keep_users) = 0) AS unexpected_users_remaining;
END$$
DELIMITER ;

CALL fulbii_cleanup_demo_data();

DROP PROCEDURE IF EXISTS fulbii_cleanup_demo_data;
DROP PROCEDURE IF EXISTS fulbii_cleanup_delete_non_protected;
DROP PROCEDURE IF EXISTS fulbii_cleanup_delete_table;
