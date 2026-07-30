-- Fulbii upgrade: ratings with one decimal (0.0 to 10.0)
-- Execute once in each active database (local and cloud).

ALTER TABLE calificaciones
  MODIFY fisico DECIMAL(3,1) NOT NULL,
  MODIFY arquero DECIMAL(3,1) NOT NULL,
  MODIFY delantero DECIMAL(3,1) NOT NULL,
  MODIFY mediocampo DECIMAL(3,1) NOT NULL,
  MODIFY defensa DECIMAL(3,1) NOT NULL;

ALTER TABLE group_pichanga_ratings
  MODIFY fisico DECIMAL(3,1) NOT NULL,
  MODIFY arquero DECIMAL(3,1) NOT NULL,
  MODIFY delantero DECIMAL(3,1) NOT NULL,
  MODIFY mediocampo DECIMAL(3,1) NOT NULL,
  MODIFY defensa DECIMAL(3,1) NOT NULL;

ALTER TABLE historial_calificacion
  MODIFY puntaje DECIMAL(3,1) NULL COMMENT '0.0 - 10.0';
