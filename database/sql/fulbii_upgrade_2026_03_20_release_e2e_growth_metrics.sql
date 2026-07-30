-- Release E2E + Operacion + Growth Metrics
-- Ejecutar una sola vez en la base de datos fulbii.

-- 1) Queue database (Laravel)
CREATE TABLE IF NOT EXISTS jobs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  queue VARCHAR(255) NOT NULL,
  payload LONGTEXT NOT NULL,
  attempts TINYINT UNSIGNED NOT NULL,
  reserved_at INT UNSIGNED NULL,
  available_at INT UNSIGNED NOT NULL,
  created_at INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  KEY idx_jobs_queue (queue),
  KEY idx_jobs_reserved (reserved_at)
) ;

CREATE TABLE IF NOT EXISTS job_batches (
  id VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  total_jobs INT NOT NULL,
  pending_jobs INT NOT NULL,
  failed_jobs INT NOT NULL,
  failed_job_ids LONGTEXT NOT NULL,
  options MEDIUMTEXT NULL,
  cancelled_at INT NULL,
  created_at INT NOT NULL,
  finished_at INT NULL,
  PRIMARY KEY (id)
);

-- 2) Product analytics events (append-only)
CREATE TABLE IF NOT EXISTS product_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_name VARCHAR(80) NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  club_id BIGINT UNSIGNED NULL,
  pichanga_id BIGINT UNSIGNED NULL,
  source VARCHAR(40) NOT NULL DEFAULT 'api',
  metadata_json LONGTEXT NULL,
  happened_at DATETIME NOT NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pe_event_time (event_name, happened_at),
  KEY idx_pe_user_time (user_id, happened_at),
  KEY idx_pe_club_time (club_id, happened_at),
  KEY idx_pe_pichanga_time (pichanga_id, happened_at)
) ;
