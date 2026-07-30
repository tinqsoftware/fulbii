-- Fulbii social block: pichanga feed + comments + ratings + favorite fields


SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS group_pichanga_posts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pichanga_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  post_type ENUM('text','photo') NOT NULL DEFAULT 'text',
  content VARCHAR(500) NULL,
  photo_url VARCHAR(500) NULL,
  status ENUM('active','removed') NOT NULL DEFAULT 'active',
  removed_by_user_id BIGINT UNSIGNED NULL,
  removed_reason VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_gppost_pichanga_status_created (pichanga_id, status, created_at),
  CONSTRAINT fk_gppost_pichanga FOREIGN KEY (pichanga_id) REFERENCES group_pichangas(id) ON DELETE CASCADE,
  CONSTRAINT fk_gppost_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS group_pichanga_comments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  post_id BIGINT UNSIGNED NOT NULL,
  pichanga_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  content VARCHAR(500) NOT NULL,
  status ENUM('active','removed') NOT NULL DEFAULT 'active',
  removed_by_user_id BIGINT UNSIGNED NULL,
  removed_reason VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_gpcomment_post_status_created (post_id, status, created_at),
  KEY idx_gpcomment_pichanga_status_created (pichanga_id, status, created_at),
  CONSTRAINT fk_gpcomment_post FOREIGN KEY (post_id) REFERENCES group_pichanga_posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_gpcomment_pichanga FOREIGN KEY (pichanga_id) REFERENCES group_pichangas(id) ON DELETE CASCADE,
  CONSTRAINT fk_gpcomment_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS group_pichanga_ratings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pichanga_id BIGINT UNSIGNED NOT NULL,
  rater_user_id BIGINT UNSIGNED NOT NULL,
  rated_user_id BIGINT UNSIGNED NOT NULL,
  fisico DECIMAL(3,1) NOT NULL,
  arquero DECIMAL(3,1) NOT NULL,
  delantero DECIMAL(3,1) NOT NULL,
  mediocampo DECIMAL(3,1) NOT NULL,
  defensa DECIMAL(3,1) NOT NULL,
  comentario VARCHAR(500) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_gprating_pichanga_rater_rated (pichanga_id, rater_user_id, rated_user_id),
  KEY idx_gprating_rated_created (rated_user_id, created_at),
  CONSTRAINT fk_gprating_pichanga FOREIGN KEY (pichanga_id) REFERENCES group_pichangas(id) ON DELETE CASCADE,
  CONSTRAINT fk_gprating_rater FOREIGN KEY (rater_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_gprating_rated FOREIGN KEY (rated_user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

CREATE TABLE IF NOT EXISTS user_favorite_fields (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  polideportivo_id INT UNSIGNED NOT NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_uff_user_field (user_id, polideportivo_id),
  KEY idx_uff_field_created (polideportivo_id, created_at),
  CONSTRAINT fk_uff_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ;

SET FOREIGN_KEY_CHECKS = 1;
