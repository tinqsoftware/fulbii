-- Fulbii demo-data cleanup: AUDIT ONLY
-- Compatible with phpMyAdmin / MySQL 8+. This script does not modify data.
-- Change this value only when you deliberately need a different
-- environment-specific keep list (local: '1,38').
-- Select the intended Fulbii database in phpMyAdmin before importing.

SET @fulbii_cleanup_keep_users = '1,38,83,84,85';

DROP PROCEDURE IF EXISTS fulbii_cleanup_preview_count;
DELIMITER $$
CREATE PROCEDURE fulbii_cleanup_preview_count(IN requested_table VARCHAR(64))
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = requested_table
    ) THEN
        SET @preview_sql = CONCAT(
            'SELECT ', QUOTE(requested_table), ' AS table_name, COUNT(*) AS rows_to_remove FROM `',
            REPLACE(requested_table, '`', '``'), '`'
        );
        PREPARE preview_statement FROM @preview_sql;
        EXECUTE preview_statement;
        DEALLOCATE PREPARE preview_statement;
    ELSE
        SELECT requested_table AS table_name, NULL AS rows_to_remove, 'table_missing_skipped' AS note;
    END IF;
END$$
DELIMITER ;

SELECT 'protected_users_check' AS section,
       COUNT(*) AS protected_users_found,
       1 + LENGTH(@fulbii_cleanup_keep_users) - LENGTH(REPLACE(@fulbii_cleanup_keep_users, ',', '')) AS protected_users_expected,
       CASE WHEN COUNT(*) = 1 + LENGTH(@fulbii_cleanup_keep_users) - LENGTH(REPLACE(@fulbii_cleanup_keep_users, ',', '')) THEN 'OK: safe to continue after reviewing counts'
            ELSE 'STOP: one or more protected users are missing' END AS status
FROM users
WHERE FIND_IN_SET(CAST(id AS CHAR), @fulbii_cleanup_keep_users) > 0;

SELECT id, nick, name, email, avatar_url
FROM users
WHERE FIND_IN_SET(CAST(id AS CHAR), @fulbii_cleanup_keep_users) > 0
ORDER BY id;

SELECT 'users_to_keep' AS metric, COUNT(*) AS total FROM users WHERE FIND_IN_SET(CAST(id AS CHAR), @fulbii_cleanup_keep_users) > 0
UNION ALL SELECT 'users_to_remove', COUNT(*) FROM users WHERE FIND_IN_SET(CAST(id AS CHAR), @fulbii_cleanup_keep_users) = 0
UNION ALL SELECT 'users_total', COUNT(*) FROM users;

CALL fulbii_cleanup_preview_count('polideportivo');
CALL fulbii_cleanup_preview_count('cancha');
CALL fulbii_cleanup_preview_count('clubs');
CALL fulbii_cleanup_preview_count('club_user');
CALL fulbii_cleanup_preview_count('group_pichangas');
CALL fulbii_cleanup_preview_count('group_pichanga_participants');
CALL fulbii_cleanup_preview_count('group_pichanga_waitlist');
CALL fulbii_cleanup_preview_count('group_pichanga_external_requests');
CALL fulbii_cleanup_preview_count('group_pichanga_posts');
CALL fulbii_cleanup_preview_count('group_pichanga_comments');
CALL fulbii_cleanup_preview_count('group_pichanga_ratings');
CALL fulbii_cleanup_preview_count('club_challenges');
CALL fulbii_cleanup_preview_count('club_challenge_messages');
CALL fulbii_cleanup_preview_count('club_group_messages');
CALL fulbii_cleanup_preview_count('calificaciones');
CALL fulbii_cleanup_preview_count('historial_calificacion');
CALL fulbii_cleanup_preview_count('field_submissions');
CALL fulbii_cleanup_preview_count('field_submission_photos');
CALL fulbii_cleanup_preview_count('polideportivo_photos');
CALL fulbii_cleanup_preview_count('cancha_photos');
CALL fulbii_cleanup_preview_count('push_notifications');
CALL fulbii_cleanup_preview_count('push_dispatch_logs');
CALL fulbii_cleanup_preview_count('reports');
CALL fulbii_cleanup_preview_count('strikes');
CALL fulbii_cleanup_preview_count('user_profile_clips');
CALL fulbii_cleanup_preview_count('watch_match_sessions');
CALL fulbii_cleanup_preview_count('failed_jobs');
CALL fulbii_cleanup_preview_count('evento');
CALL fulbii_cleanup_preview_count('pichanga');

DROP PROCEDURE IF EXISTS fulbii_cleanup_preview_count;
