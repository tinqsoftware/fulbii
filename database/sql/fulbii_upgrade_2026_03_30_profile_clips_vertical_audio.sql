-- Fulbii upgrade: profile clips vertical + audio metadata
-- Execute once on active database.

START TRANSACTION;

ALTER TABLE user_profile_clips
  ADD COLUMN IF NOT EXISTS has_audio TINYINT(1) NOT NULL DEFAULT 1 AFTER height;

COMMIT;
