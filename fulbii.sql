-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Apr 09, 2026 at 12:16 AM
-- Server version: 10.4.26-MariaDB-1:10.4.26+maria~ubu1804
-- PHP Version: 7.4.32

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `fulbii`
--

-- --------------------------------------------------------

--
-- Table structure for table `calificaciones`
--

CREATE TABLE `calificaciones` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `club_id` bigint(20) UNSIGNED DEFAULT NULL,
  `user_calificador_id` bigint(20) UNSIGNED NOT NULL,
  `user_calificado_id` bigint(20) UNSIGNED NOT NULL,
  `fisico` decimal(3,1) NOT NULL,
  `arquero` decimal(3,1) NOT NULL,
  `delantero` decimal(3,1) NOT NULL,
  `mediocampo` decimal(3,1) NOT NULL,
  `defensa` decimal(3,1) NOT NULL,
  `comentario` varchar(500) DEFAULT NULL,
  `ocultada_por_calificado_at` timestamp NULL DEFAULT NULL,
  `silenciada_por_admin_at` timestamp NULL DEFAULT NULL,
  `ocultada_motivo` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  `es_autocalificacion` tinyint(1) GENERATED ALWAYS AS (`user_calificador_id` = `user_calificado_id`) VIRTUAL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `calificaciones`
--

INSERT INTO `calificaciones` (`id`, `club_id`, `user_calificador_id`, `user_calificado_id`, `fisico`, `arquero`, `delantero`, `mediocampo`, `defensa`, `comentario`, `ocultada_por_calificado_at`, `silenciada_por_admin_at`, `ocultada_motivo`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 1, 1, 1, '4.0', '1.0', '5.0', '3.0', '2.0', NULL, NULL, NULL, NULL, '2025-11-05 14:17:51', '2025-11-05 14:17:51', NULL),
(2, 1, 3, 3, '3.0', '1.0', '5.0', '3.0', '2.0', NULL, NULL, NULL, NULL, '2025-11-05 15:28:34', '2025-11-05 15:41:52', NULL),
(3, 1, 3, 9, '2.0', '2.0', '3.0', '5.0', '4.0', NULL, NULL, NULL, NULL, '2025-11-05 15:28:58', '2025-11-05 15:42:03', NULL),
(4, 1, 24, 24, '4.0', '1.0', '4.0', '3.0', '4.0', NULL, NULL, NULL, NULL, '2025-11-05 15:28:58', '2025-11-06 03:18:41', NULL),
(5, 1, 24, 7, '4.0', '1.0', '4.0', '5.0', '3.0', NULL, NULL, NULL, NULL, '2025-11-05 15:28:58', '2025-11-06 03:18:43', NULL),
(6, 1, 10, 10, '4.0', '1.0', '5.0', '4.0', '3.0', NULL, NULL, NULL, NULL, '2025-11-05 15:28:58', '2025-11-05 15:43:16', NULL),
(7, 1, 10, 5, '4.0', '5.0', '2.0', '2.0', '2.0', NULL, NULL, NULL, NULL, '2025-11-05 15:28:58', '2025-11-05 15:44:00', NULL),
(8, 1, 10, 7, '4.0', '3.0', '4.0', '4.0', '5.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:44:02', NULL),
(9, 1, 10, 11, '3.0', '1.0', '3.0', '3.0', '3.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:44:04', NULL),
(10, 1, 10, 13, '4.0', '2.0', '4.0', '3.0', '3.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:45:23', NULL),
(11, 1, 10, 9, '2.0', '2.0', '3.0', '4.0', '4.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:45:25', NULL),
(12, 1, 10, 24, '4.0', '1.0', '5.0', '3.0', '1.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-06 03:18:53', NULL),
(13, 1, 7, 7, '3.0', '1.0', '2.0', '3.0', '4.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:45:49', NULL),
(14, 1, 9, 9, '5.0', '5.0', '5.0', '5.0', '5.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:45:53', NULL),
(15, 1, 13, 13, '3.0', '1.0', '4.0', '3.0', '2.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:46:21', NULL),
(16, 1, 13, 10, '4.0', '1.0', '4.0', '3.0', '2.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:46:25', NULL),
(17, 1, 4, 4, '4.0', '4.0', '2.0', '3.0', '5.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:50:08', NULL),
(18, 1, 6, 6, '5.0', '1.0', '3.0', '5.0', '3.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:50:13', NULL),
(19, 1, 14, 14, '4.0', '1.0', '4.0', '5.0', '5.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:50:18', NULL),
(20, 1, 14, 1, '4.0', '1.0', '1.0', '2.0', '4.0', NULL, NULL, NULL, NULL, '2025-11-05 15:30:02', '2025-11-05 15:50:19', NULL),
(25, 1, 1, 14, '3.0', '1.0', '3.0', '3.0', '2.0', NULL, NULL, NULL, NULL, '2025-11-05 16:10:04', '2025-11-05 16:10:04', NULL),
(26, 1, 1, 11, '3.0', '2.0', '2.0', '3.0', '3.0', NULL, NULL, NULL, NULL, '2025-11-05 17:16:06', '2025-11-05 17:16:06', NULL),
(27, 1, 15, 15, '2.0', '4.0', '2.0', '3.0', '3.0', NULL, NULL, NULL, NULL, '2025-11-05 17:54:59', '2025-11-05 17:58:41', NULL),
(28, 1, 15, 14, '3.0', '1.0', '2.0', '3.0', '1.0', NULL, NULL, NULL, NULL, '2025-11-05 17:56:38', '2025-11-05 17:56:38', NULL),
(29, 1, 15, 13, '3.0', '1.0', '3.0', '2.0', '2.0', NULL, NULL, NULL, NULL, '2025-11-05 17:57:13', '2025-11-05 17:57:13', NULL),
(30, 1, 12, 12, '2.0', '3.0', '4.0', '4.0', '3.0', NULL, NULL, NULL, NULL, '2025-11-05 22:24:02', '2025-11-05 22:24:02', NULL),
(31, 1, 12, 16, '1.0', '1.0', '1.0', '1.0', '1.0', NULL, NULL, NULL, NULL, '2025-11-05 22:44:55', '2025-11-05 22:44:55', NULL),
(32, 1, 13, 3, '3.0', '1.0', '4.0', '3.0', '2.0', NULL, NULL, NULL, NULL, '2025-11-06 03:15:14', '2025-11-06 03:15:14', NULL),
(33, 1, 23, 23, '3.0', '1.0', '3.0', '3.0', '4.0', NULL, NULL, NULL, NULL, '2025-11-06 23:22:27', '2025-11-06 23:22:27', NULL),
(34, NULL, 30, 30, '4.0', '2.0', '4.0', '2.0', '2.0', NULL, NULL, NULL, NULL, '2025-11-12 03:04:58', '2025-11-12 03:04:58', NULL),
(35, 2, 29, 29, '4.0', '1.0', '2.0', '3.0', '5.0', NULL, NULL, NULL, NULL, '2025-11-12 03:06:42', '2025-11-12 03:06:42', NULL),
(36, 1, 11, 11, '4.0', '2.0', '3.0', '4.0', '4.0', NULL, NULL, NULL, NULL, '2025-11-20 01:10:26', '2025-11-20 01:10:26', NULL),
(37, 1, 11, 9, '2.0', '1.0', '3.0', '4.0', '5.0', NULL, NULL, NULL, NULL, '2025-11-20 01:10:50', '2025-11-20 01:10:50', NULL),
(38, 1, 1, 31, '4.0', '2.0', '3.0', '3.0', '4.0', NULL, NULL, NULL, NULL, '2025-11-21 17:57:08', '2025-11-21 17:57:08', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `cancha`
--

CREATE TABLE `cancha` (
  `id` int(11) NOT NULL,
  `id_polideportivo` int(11) DEFAULT NULL,
  `nombre` varchar(250) DEFAULT NULL,
  `anchom2` varchar(50) DEFAULT NULL,
  `largom2` varchar(50) DEFAULT NULL,
  `equiposvs` varchar(5) DEFAULT NULL COMMENT '2 vs 2, 3 vs 3, \r\n4 vs 4, 5 vs 5, 6 vs 6, 7 vs 7,\r\n8 vs 8 , 9 vs 9 , 11 vs 11',
  `tipo_superficie` enum('losa','sintetico','artificial') DEFAULT NULL,
  `formato_vs` enum('6v6','7v7','9v9') DEFAULT NULL,
  `id_cancha_unida` int(11) DEFAULT NULL COMMENT 'si se junta a una cancha',
  `url_foto` varchar(300) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `cancha`
--

INSERT INTO `cancha` (`id`, `id_polideportivo`, `nombre`, `anchom2`, `largom2`, `equiposvs`, `tipo_superficie`, `formato_vs`, `id_cancha_unida`, `url_foto`, `created_at`, `updated_at`) VALUES
(1, 1, 'Cancha 7 vs 7 - A', '30', '50', '7', NULL, NULL, NULL, NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(2, 1, 'Cancha 5 vs 5 - B', '20', '40', '5', NULL, NULL, NULL, NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(3, 2, 'Cancha 7 vs 7 - A', '30', '50', '7', NULL, NULL, NULL, NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(4, 2, 'Cancha 6 vs 6 - B', '25', '45', '6', NULL, NULL, NULL, NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(5, 3, 'Cancha 5 vs 5 - A', '20', '40', '5', NULL, NULL, NULL, NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(6, 3, 'Cancha 7 vs 7 - B', '30', '50', '7', NULL, NULL, NULL, NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(7, 4, 'Cancha 5 vs 5 - A', '20', '40', '5', NULL, NULL, NULL, NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(8, 4, 'Cancha 8 vs 8 - B', '35', '55', '8', NULL, NULL, NULL, NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19');

-- --------------------------------------------------------

--
-- Table structure for table `clubs`
--

CREATE TABLE `clubs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `slug` varchar(160) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `logo_url` varchar(255) DEFAULT NULL,
  `estado` tinyint(4) NOT NULL DEFAULT 1,
  `is_visible` tinyint(1) NOT NULL DEFAULT 1,
  `pichanga_create_scope` enum('admins','members') NOT NULL DEFAULT 'admins',
  `renotify_scope` enum('admins','members') NOT NULL DEFAULT 'admins',
  `renotify_cooldown_minutes` smallint(5) UNSIGNED NOT NULL DEFAULT 30,
  `renotify_max_per_pichanga` smallint(5) UNSIGNED NOT NULL DEFAULT 5,
  `audience_max_degree` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `join_code` char(12) DEFAULT NULL,
  `link_join_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `auto_reminder_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `auto_reminder_48h_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `auto_reminder_24h_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `clubs`
--

INSERT INTO `clubs` (`id`, `nombre`, `slug`, `descripcion`, `logo_url`, `estado`, `is_visible`, `pichanga_create_scope`, `renotify_scope`, `renotify_cooldown_minutes`, `renotify_max_per_pichanga`, `audience_max_degree`, `join_code`, `link_join_enabled`, `auto_reminder_enabled`, `auto_reminder_48h_enabled`, `auto_reminder_24h_enabled`, `created_by`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'PSSFJ', 'PSSFJ', NULL, 'clubs/nAddaWHLujsghcPj72xllvkPjGhSXlWOB5OwYCWo.jpg', 1, 1, 'admins', 'admins', 30, 5, 1, '000000000001', 1, 1, 1, 1, 1, '2025-11-05 14:14:32', '2026-03-20 00:17:58', NULL),
(2, 'MAC', 'mac', NULL, 'clubs/NMJP9nw6oPTuq597Ntn44nf30HvA6CVX4pSTSEaq.jpg', 1, 1, 'admins', 'admins', 30, 5, 1, '000000000002', 1, 1, 1, 1, 1, '2025-11-12 03:06:10', '2026-03-20 00:17:58', NULL),
(3, 'ejemplo', 'ejemplo', NULL, NULL, 1, 1, 'members', 'members', 30, 5, 3, 'FJ2U4YASOTK0', 1, 1, 1, 1, 38, '2026-03-29 07:51:25', '2026-03-29 07:51:25', NULL),
(4, 'ejemplo 2', 'ejemplo-2', NULL, NULL, 1, 1, 'members', 'members', 30, 5, 3, 'FIX927CWSTNY', 1, 1, 1, 1, 1, '2026-03-29 08:34:09', '2026-04-02 02:06:13', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `club_challenges`
--

CREATE TABLE `club_challenges` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `challenger_club_id` bigint(20) UNSIGNED NOT NULL,
  `challenged_club_id` bigint(20) UNSIGNED NOT NULL,
  `created_by_user_id` bigint(20) UNSIGNED NOT NULL,
  `coordinator_challenger_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `coordinator_challenged_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `team_size` tinyint(3) UNSIGNED NOT NULL DEFAULT 6,
  `challenge_window` enum('next_week','next_fortnight','next_month') NOT NULL DEFAULT 'next_week',
  `status` enum('pending','negotiating','configuring','confirmed','rejected','cancelled','expired') NOT NULL DEFAULT 'pending',
  `requested_note` varchar(500) DEFAULT NULL,
  `rejected_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `rejected_reason` varchar(255) DEFAULT NULL,
  `cancelled_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `cancelled_reason` varchar(255) DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `confirmed_pichanga_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `club_challenges`
--

INSERT INTO `club_challenges` (`id`, `challenger_club_id`, `challenged_club_id`, `created_by_user_id`, `coordinator_challenger_user_id`, `coordinator_challenged_user_id`, `team_size`, `challenge_window`, `status`, `requested_note`, `rejected_by_user_id`, `rejected_reason`, `cancelled_by_user_id`, `cancelled_reason`, `expires_at`, `confirmed_at`, `confirmed_pichanga_id`, `created_at`, `updated_at`) VALUES
(1, 4, 3, 1, 1, NULL, 6, 'next_week', 'confirmed', NULL, NULL, NULL, NULL, NULL, '2026-04-12 00:34:40', '2026-04-05 00:42:14', 7, '2026-04-05 05:34:40', '2026-04-05 05:42:14');

-- --------------------------------------------------------

--
-- Table structure for table `club_challenge_configurations`
--

CREATE TABLE `club_challenge_configurations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `challenge_id` bigint(20) UNSIGNED NOT NULL,
  `proposed_by_user_id` bigint(20) UNSIGNED NOT NULL,
  `field_option_id` bigint(20) UNSIGNED NOT NULL,
  `time_option_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('pending','accepted','rejected','cancelled') NOT NULL DEFAULT 'pending',
  `accepted_by_challenger_at` datetime DEFAULT NULL,
  `accepted_by_challenged_at` datetime DEFAULT NULL,
  `rejected_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `rejected_reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `club_challenge_configurations`
--

INSERT INTO `club_challenge_configurations` (`id`, `challenge_id`, `proposed_by_user_id`, `field_option_id`, `time_option_id`, `status`, `accepted_by_challenger_at`, `accepted_by_challenged_at`, `rejected_by_user_id`, `rejected_reason`, `created_at`, `updated_at`) VALUES
(1, 1, 38, 1, 1, 'accepted', '2026-04-05 00:42:14', '2026-04-05 00:42:14', NULL, NULL, '2026-04-05 05:41:20', '2026-04-05 05:42:14');

-- --------------------------------------------------------

--
-- Table structure for table `club_challenge_field_options`
--

CREATE TABLE `club_challenge_field_options` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `challenge_id` bigint(20) UNSIGNED NOT NULL,
  `proposed_by_user_id` bigint(20) UNSIGNED NOT NULL,
  `polideportivo_id` int(10) UNSIGNED DEFAULT NULL,
  `field_name` varchar(255) DEFAULT NULL,
  `field_address` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `status` enum('proposed','accepted','rejected') NOT NULL DEFAULT 'proposed',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `club_challenge_field_options`
--

INSERT INTO `club_challenge_field_options` (`id`, `challenge_id`, `proposed_by_user_id`, `polideportivo_id`, `field_name`, `field_address`, `latitude`, `longitude`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 38, NULL, '1', NULL, NULL, NULL, 'accepted', '2026-04-05 05:40:20', '2026-04-05 05:42:14');

-- --------------------------------------------------------

--
-- Table structure for table `club_challenge_messages`
--

CREATE TABLE `club_challenge_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `challenge_id` bigint(20) UNSIGNED NOT NULL,
  `sender_user_id` bigint(20) UNSIGNED NOT NULL,
  `message_type` enum('text','system') NOT NULL DEFAULT 'text',
  `content` varchar(1200) NOT NULL,
  `metadata_json` longtext DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `club_challenge_messages`
--

INSERT INTO `club_challenge_messages` (`id`, `challenge_id`, `sender_user_id`, `message_type`, `content`, `metadata_json`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'system', 'ejemplo 2 retó a ejemplo (6 vs 6).', '{\"challenge_id\":1,\"window\":\"next_week\"}', '2026-04-05 05:34:40', '2026-04-05 05:34:40'),
(2, 1, 38, 'system', 'ricci está coordinando el reto.', '{\"side\":\"challenger\"}', '2026-04-05 05:37:03', '2026-04-05 05:37:03'),
(3, 1, 1, 'text', 'ejemplo', NULL, '2026-04-05 05:37:19', '2026-04-05 05:37:19'),
(4, 1, 1, 'text', 'nuevo chat', NULL, '2026-04-05 05:37:30', '2026-04-05 05:37:30'),
(5, 1, 1, 'text', 'ejemplo', NULL, '2026-04-05 05:38:35', '2026-04-05 05:38:35'),
(6, 1, 1, 'text', 'nuevo', NULL, '2026-04-05 05:38:43', '2026-04-05 05:38:43'),
(7, 1, 38, 'system', 'ricci está coordinando el reto.', '{\"side\":\"challenger\"}', '2026-04-05 05:39:09', '2026-04-05 05:39:09'),
(8, 1, 38, 'system', 'Se propuso fecha/hora para el reto.', '{\"time_option_id\":1}', '2026-04-05 05:39:47', '2026-04-05 05:39:47'),
(9, 1, 38, 'system', 'Se propuso una cancha para el reto.', '{\"field_option_id\":1}', '2026-04-05 05:40:20', '2026-04-05 05:40:20'),
(10, 1, 1, 'text', 'mensaje', NULL, '2026-04-05 05:41:10', '2026-04-05 05:41:10'),
(11, 1, 1, 'text', 'jjj', NULL, '2026-04-05 05:41:13', '2026-04-05 05:41:13'),
(12, 1, 38, 'system', 'Se propuso configuración de pichanga.', '{\"configuration_id\":1,\"field_option_id\":1,\"time_option_id\":1,\"invited_link_enabled\":false}', '2026-04-05 05:41:21', '2026-04-05 05:41:21'),
(13, 1, 38, 'system', 'Configuración aceptada por un grupo. Falta la otra confirmación.', '{\"configuration_id\":1}', '2026-04-05 05:41:37', '2026-04-05 05:41:37'),
(14, 1, 1, 'system', 'aricci está coordinando el reto.', '{\"side\":\"challenger\"}', '2026-04-05 05:42:09', '2026-04-05 05:42:09'),
(15, 1, 1, 'system', 'Reto confirmado. Se creó una pichanga compartida.', '{\"configuration_id\":1,\"pichanga_id\":7}', '2026-04-05 05:42:14', '2026-04-05 05:42:14');

-- --------------------------------------------------------

--
-- Table structure for table `club_challenge_time_options`
--

CREATE TABLE `club_challenge_time_options` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `challenge_id` bigint(20) UNSIGNED NOT NULL,
  `proposed_by_user_id` bigint(20) UNSIGNED NOT NULL,
  `starts_at` datetime NOT NULL,
  `duration_minutes` smallint(5) UNSIGNED NOT NULL DEFAULT 90,
  `status` enum('proposed','accepted','rejected') NOT NULL DEFAULT 'proposed',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `club_challenge_time_options`
--

INSERT INTO `club_challenge_time_options` (`id`, `challenge_id`, `proposed_by_user_id`, `starts_at`, `duration_minutes`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 38, '2026-04-10 14:00:00', 60, 'accepted', '2026-04-05 05:39:47', '2026-04-05 05:42:14');

-- --------------------------------------------------------

--
-- Table structure for table `club_invitations`
--

CREATE TABLE `club_invitations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `club_id` bigint(20) UNSIGNED NOT NULL,
  `invited_email` varchar(255) NOT NULL,
  `invited_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `invited_by_user_id` bigint(20) UNSIGNED NOT NULL,
  `token` char(36) NOT NULL,
  `status` enum('pending','accepted','revoked','expired') NOT NULL DEFAULT 'pending',
  `accepted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `club_join_requests`
--

CREATE TABLE `club_join_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `club_id` bigint(20) UNSIGNED NOT NULL,
  `requester_user_id` bigint(20) UNSIGNED NOT NULL,
  `requested_via` enum('search','link') NOT NULL DEFAULT 'search',
  `status` enum('pending','accepted','rejected','cancelled','expired') NOT NULL DEFAULT 'pending',
  `requested_at` datetime DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `decided_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `club_join_requests`
--

INSERT INTO `club_join_requests` (`id`, `club_id`, `requester_user_id`, `requested_via`, `status`, `requested_at`, `decided_at`, `decided_by_user_id`, `note`, `created_at`, `updated_at`) VALUES
(1, 3, 1, 'search', 'rejected', '2026-03-29 02:51:37', '2026-03-29 02:52:23', 38, NULL, '2026-03-29 07:51:37', '2026-03-29 07:52:23'),
(2, 3, 1, 'search', 'rejected', '2026-03-29 02:52:44', '2026-03-29 02:52:56', 38, NULL, '2026-03-29 07:52:44', '2026-03-29 07:52:56'),
(3, 3, 1, 'search', 'rejected', '2026-03-29 03:33:02', '2026-03-29 03:33:12', 38, NULL, '2026-03-29 08:33:02', '2026-03-29 08:33:12'),
(4, 3, 1, 'search', 'accepted', '2026-03-29 03:33:21', '2026-04-07 15:08:04', 38, NULL, '2026-03-29 08:33:21', '2026-04-07 20:08:04'),
(5, 4, 38, 'search', 'accepted', '2026-03-29 03:34:21', '2026-03-29 03:34:38', 1, NULL, '2026-03-29 08:34:21', '2026-03-29 08:34:39');

-- --------------------------------------------------------

--
-- Table structure for table `club_user`
--

CREATE TABLE `club_user` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `club_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `rol` enum('admin','miembro') NOT NULL DEFAULT 'miembro',
  `estado` tinyint(4) NOT NULL DEFAULT 1,
  `joined_at` timestamp NULL DEFAULT current_timestamp(),
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `club_user`
--

INSERT INTO `club_user` (`id`, `club_id`, `user_id`, `rol`, `estado`, `joined_at`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 1, 1, 'admin', 1, '2025-11-05 14:14:32', '2025-11-05 14:14:32', '2025-11-05 14:14:32', NULL),
(2, 1, 3, 'miembro', 1, '2025-11-05 15:00:46', '2025-11-05 15:00:46', '2025-11-05 15:00:46', NULL),
(3, 1, 4, 'miembro', 1, '2025-11-05 15:00:54', '2025-11-05 15:00:54', '2025-11-05 15:00:54', NULL),
(4, 1, 5, 'miembro', 1, '2025-11-05 15:01:02', '2025-11-05 15:01:02', '2025-11-05 15:01:02', NULL),
(5, 1, 6, 'miembro', 1, '2025-11-05 15:01:10', '2025-11-05 15:01:10', '2025-11-05 15:01:10', NULL),
(6, 1, 7, 'miembro', 1, '2025-11-05 15:01:17', '2025-11-05 15:01:17', '2025-11-05 15:01:17', NULL),
(8, 1, 9, 'miembro', 1, '2025-11-05 15:01:32', '2025-11-05 15:01:32', '2025-11-05 15:01:32', NULL),
(9, 1, 10, 'miembro', 1, '2025-11-05 15:01:39', '2025-11-05 15:01:39', '2025-11-05 15:01:39', NULL),
(10, 1, 11, 'miembro', 1, '2025-11-05 15:01:46', '2025-11-05 15:01:46', '2025-11-05 15:01:46', NULL),
(11, 1, 12, 'miembro', 1, '2025-11-05 15:01:59', '2025-11-05 15:01:59', '2025-11-05 15:01:59', NULL),
(12, 1, 13, 'miembro', 1, '2025-11-05 15:02:09', '2025-11-05 15:02:09', '2025-11-05 15:02:09', NULL),
(13, 1, 14, 'miembro', 1, '2025-11-05 15:02:17', '2025-11-05 15:02:17', '2025-11-05 15:02:17', NULL),
(14, 1, 15, 'miembro', 1, '2025-11-05 15:02:23', '2025-11-05 15:02:23', '2025-11-05 15:02:23', NULL),
(15, 1, 16, 'miembro', 1, '2025-11-05 15:02:37', '2025-11-05 15:02:37', '2025-11-05 15:02:37', NULL),
(16, 1, 17, 'miembro', 1, '2025-11-05 15:02:43', '2025-11-05 15:02:43', '2025-11-05 15:02:43', NULL),
(17, 1, 18, 'miembro', 1, '2025-11-05 15:02:51', '2025-11-05 15:02:51', '2025-11-05 15:02:51', NULL),
(18, 1, 19, 'miembro', 1, '2025-11-05 15:02:58', '2025-11-05 15:02:58', '2025-11-05 15:02:58', NULL),
(19, 1, 20, 'miembro', 1, '2025-11-05 15:03:03', '2025-11-05 15:03:03', '2025-11-05 15:03:03', NULL),
(20, 1, 23, 'miembro', 1, '2025-11-05 15:03:09', '2025-11-05 15:03:09', '2025-11-06 03:22:46', NULL),
(21, 1, 22, 'miembro', 1, '2025-11-05 15:57:07', '2025-11-05 15:57:07', '2025-11-05 15:57:07', NULL),
(22, 1, 25, 'miembro', 1, '2025-11-06 01:22:26', '2025-11-06 01:22:26', '2025-11-06 01:22:26', NULL),
(23, 1, 26, 'miembro', 1, '2025-11-06 01:22:37', '2025-11-06 01:22:37', '2025-11-06 01:22:37', NULL),
(24, 1, 24, 'miembro', 1, '2025-11-06 03:17:20', '2025-11-06 03:17:20', '2025-11-06 03:17:20', NULL),
(26, 2, 29, 'admin', 1, '2025-11-12 03:06:35', '2025-11-12 03:06:35', '2025-11-12 03:06:35', NULL),
(27, 1, 31, 'miembro', 1, '2025-11-21 17:56:51', '2025-11-21 17:56:51', '2025-11-21 17:56:51', NULL),
(28, 3, 38, 'admin', 1, '2026-03-29 07:51:25', '2026-03-29 07:51:25', '2026-03-29 07:51:25', NULL),
(29, 4, 1, 'admin', 1, '2026-03-29 08:34:09', '2026-03-29 08:34:09', '2026-03-29 08:34:09', NULL),
(30, 4, 38, 'miembro', 1, '2026-03-29 08:34:38', '2026-03-29 08:34:38', '2026-03-29 08:34:38', NULL),
(31, 3, 1, 'miembro', 1, '2026-04-07 20:08:04', '2026-04-07 20:08:04', '2026-04-07 20:08:04', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `distritos`
--

CREATE TABLE `distritos` (
  `id` int(11) NOT NULL,
  `nombres` varchar(200) DEFAULT NULL,
  `id_provincia` int(11) DEFAULT NULL,
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `equipos`
--

CREATE TABLE `equipos` (
  `id` int(11) NOT NULL,
  `id_pichanga` int(11) DEFAULT NULL,
  `nombre_equipo` varchar(200) DEFAULT NULL COMMENT 'nombre A, B, C, etc',
  `id_formacion` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `evento`
--

CREATE TABLE `evento` (
  `id` int(11) NOT NULL,
  `id_cancha` int(11) DEFAULT NULL,
  `nombre` varchar(250) DEFAULT NULL,
  `fecha` date DEFAULT NULL,
  `hora` time DEFAULT NULL,
  `duracion` varchar(10) DEFAULT NULL,
  `invitacion_abierta` varchar(2) DEFAULT NULL COMMENT '1 si, 0 no',
  `armado_equipos` varchar(2) DEFAULT NULL COMMENT '1 automático, 0 manual',
  `pago` varchar(2) DEFAULT NULL COMMENT '1 si, 0 no',
  `cuota` varchar(2) DEFAULT NULL COMMENT '1 automático, 0 manual',
  `pago_total` varchar(5) DEFAULT NULL COMMENT 'cantidad total de dinero',
  `cant_cuota` varchar(5) DEFAULT NULL COMMENT 'cuota calculada',
  `tipo_recaudo` varchar(2) DEFAULT NULL COMMENT '1 banco, 2 yape',
  `nro_recaudacion` varchar(80) DEFAULT NULL COMMENT 'nro cuenta, nro celular',
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `evento_usuarios`
--

CREATE TABLE `evento_usuarios` (
  `id` int(11) NOT NULL,
  `id_evento` int(11) DEFAULT NULL,
  `id_user_asistente` bigint(20) UNSIGNED DEFAULT NULL,
  `estado` varchar(2) DEFAULT NULL COMMENT '1: Pichanga vista\r\n2: En espera confirmación\r\n3: Confirmado y por jugar',
  `pago` varchar(10) DEFAULT NULL COMMENT '0: no pagado,\r\n1: pagado',
  `boucher_pago` varchar(300) DEFAULT NULL COMMENT 'url boucher',
  `boucher_verificado` varchar(2) DEFAULT NULL COMMENT '0: boucher no revisado,\r\n1: boucher revisado',
  `admin` varchar(2) DEFAULT NULL COMMENT '0 (no administrador)\r\n1 (administrador)',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `field_geometries`
--

CREATE TABLE `field_geometries` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `field_id` int(10) UNSIGNED DEFAULT NULL,
  `cancha_id` int(10) UNSIGNED DEFAULT NULL,
  `width_meters` decimal(8,2) NOT NULL,
  `length_meters` decimal(8,2) NOT NULL,
  `rotation_degrees` decimal(8,2) NOT NULL DEFAULT 0.00,
  `corners_json` longtext DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `field_submissions`
--

CREATE TABLE `field_submissions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `nombre` varchar(250) NOT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `x` varchar(50) DEFAULT NULL,
  `y` varchar(50) DEFAULT NULL,
  `celular` varchar(20) DEFAULT NULL,
  `wsp` tinyint(1) NOT NULL DEFAULT 0,
  `id_distrito` int(11) DEFAULT NULL,
  `descripcion` varchar(300) DEFAULT NULL,
  `precio_desde` varchar(10) DEFAULT NULL,
  `source_type` enum('gps','manual_map') NOT NULL DEFAULT 'gps',
  `reviewed_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `approved_polideportivo_id` int(11) DEFAULT NULL,
  `resolution_note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `field_submission_photos`
--

CREATE TABLE `field_submission_photos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `field_submission_id` bigint(20) UNSIGNED NOT NULL,
  `photo_url` varchar(500) NOT NULL,
  `status` enum('active','removed') NOT NULL DEFAULT 'active',
  `removed_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `removed_reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `formacion`
--

CREATE TABLE `formacion` (
  `id` int(11) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL COMMENT '222,\r\n312,\r\n231,\r\netc',
  `descripcion` varchar(250) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `goles`
--

CREATE TABLE `goles` (
  `id` int(11) NOT NULL,
  `id_pichanga` int(11) DEFAULT NULL,
  `id_user_gol` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `group_pichangas`
--

CREATE TABLE `group_pichangas` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `club_id` bigint(20) UNSIGNED NOT NULL,
  `rival_club_id` bigint(20) UNSIGNED DEFAULT NULL,
  `challenge_id` bigint(20) UNSIGNED DEFAULT NULL,
  `match_context` enum('regular','club_challenge') NOT NULL DEFAULT 'regular',
  `created_by_user_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(160) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `field_id` int(10) UNSIGNED DEFAULT NULL,
  `cancha_id` int(10) UNSIGNED DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `starts_at` datetime NOT NULL,
  `duration_minutes` smallint(5) UNSIGNED NOT NULL DEFAULT 60,
  `capacity` smallint(5) UNSIGNED NOT NULL,
  `status` enum('published','confirmed','cancelled','completed') NOT NULL DEFAULT 'published',
  `confirmation_mode` enum('auto_by_capacity','manual_paid') NOT NULL DEFAULT 'auto_by_capacity',
  `match_format` enum('versus','triangular','cuadrangular') NOT NULL DEFAULT 'versus',
  `team_count` tinyint(3) UNSIGNED NOT NULL DEFAULT 2,
  `players_per_team` tinyint(3) UNSIGNED NOT NULL DEFAULT 7,
  `is_open` tinyint(1) NOT NULL DEFAULT 0,
  `notify_degree` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `allow_external_requests` tinyint(1) NOT NULL DEFAULT 0,
  `invited_link_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `invited_link_code` char(16) DEFAULT NULL,
  `auto_reminder_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `auto_reminder_48h_sent_at` datetime DEFAULT NULL,
  `auto_reminder_24h_sent_at` datetime DEFAULT NULL,
  `withdraw_until` datetime DEFAULT NULL,
  `audience_sex` enum('M','F') DEFAULT NULL,
  `audience_age_min` tinyint(3) UNSIGNED DEFAULT NULL,
  `audience_age_max` tinyint(3) UNSIGNED DEFAULT NULL,
  `skill_fisico_min` tinyint(3) UNSIGNED DEFAULT NULL,
  `skill_arquero_min` tinyint(3) UNSIGNED DEFAULT NULL,
  `skill_delantero_min` tinyint(3) UNSIGNED DEFAULT NULL,
  `skill_mediocampo_min` tinyint(3) UNSIGNED DEFAULT NULL,
  `skill_defensa_min` tinyint(3) UNSIGNED DEFAULT NULL,
  `last_renotify_at` datetime DEFAULT NULL,
  `renotify_sent_count` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `group_pichangas`
--

INSERT INTO `group_pichangas` (`id`, `club_id`, `rival_club_id`, `challenge_id`, `match_context`, `created_by_user_id`, `title`, `description`, `field_id`, `cancha_id`, `address`, `starts_at`, `duration_minutes`, `capacity`, `status`, `confirmation_mode`, `match_format`, `team_count`, `players_per_team`, `is_open`, `notify_degree`, `allow_external_requests`, `invited_link_enabled`, `invited_link_code`, `auto_reminder_enabled`, `auto_reminder_48h_sent_at`, `auto_reminder_24h_sent_at`, `withdraw_until`, `audience_sex`, `audience_age_min`, `audience_age_max`, `skill_fisico_min`, `skill_arquero_min`, `skill_delantero_min`, `skill_mediocampo_min`, `skill_defensa_min`, `last_renotify_at`, `renotify_sent_count`, `created_at`, `updated_at`) VALUES
(1, 4, NULL, NULL, 'regular', 1, 'pichanga', NULL, 1, NULL, NULL, '2026-03-30 03:35:02', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, 14, 80, NULL, NULL, NULL, NULL, NULL, '2026-03-30 02:46:02', 1, '2026-03-29 08:36:09', '2026-03-30 07:46:02'),
(2, 4, NULL, NULL, 'regular', 1, NULL, NULL, 2, NULL, NULL, '2026-03-31 17:11:00', 60, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 1, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-30 18:40:08', 1, '2026-03-29 10:12:29', '2026-03-30 23:40:08'),
(3, 4, NULL, NULL, 'regular', 1, 'partido', NULL, 3, NULL, NULL, '2026-03-30 09:47:01', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-03-29 14:47:11', '2026-03-29 14:47:11'),
(4, 4, NULL, NULL, 'regular', 1, NULL, NULL, 3, NULL, NULL, '2026-04-01 15:09:00', 60, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-03-29 17:10:54', '2026-03-29 17:10:54'),
(5, 4, NULL, NULL, 'regular', 1, NULL, NULL, NULL, NULL, NULL, '2026-04-05 19:51:59', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-05 00:53:04', '2026-04-05 00:53:04'),
(6, 4, NULL, NULL, 'regular', 1, NULL, NULL, NULL, NULL, NULL, '2026-04-09 19:57:00', 60, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-05 00:57:30', '2026-04-05 00:57:30'),
(7, 4, 3, 1, 'club_challenge', 1, 'Reto 4 vs 3', 'Pichanga por reto entre grupos.', NULL, NULL, '1', '2026-04-10 14:00:00', 60, 12, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 0, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-04-05 12:23:37', 1, '2026-04-05 05:42:14', '2026-04-05 17:23:37'),
(8, 4, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-07 12:50:00', 60, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-07 17:45:46', '2026-04-07 17:45:46'),
(9, 4, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-07 13:40:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-07 18:42:37', '2026-04-07 18:42:37'),
(10, 4, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-07 13:50:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-07 18:44:03', '2026-04-07 18:44:03'),
(11, 3, NULL, NULL, 'regular', 38, NULL, NULL, 1, 1, NULL, '2026-04-08 15:05:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-07 20:06:19', '2026-04-07 20:06:19'),
(12, 3, NULL, NULL, 'regular', 38, NULL, NULL, 1, 1, NULL, '2026-04-07 20:50:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-08 01:47:27', '2026-04-08 01:47:27'),
(13, 3, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-08 02:20:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-08 07:16:28', '2026-04-08 07:16:28'),
(14, 3, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-09 02:17:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-08 07:17:55', '2026-04-08 07:17:55'),
(15, 3, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-08 11:28:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-08 16:24:33', '2026-04-08 16:24:33'),
(16, 3, NULL, NULL, 'regular', 38, NULL, NULL, 1, 1, NULL, '2026-04-08 14:33:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-08 19:31:28', '2026-04-08 19:31:28'),
(17, 3, NULL, NULL, 'regular', 38, NULL, NULL, 1, 1, NULL, '2026-04-08 16:16:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-08 21:12:47', '2026-04-08 21:12:47'),
(18, 3, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-08 19:00:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-08 23:56:37', '2026-04-08 23:56:37'),
(19, 3, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-08 21:44:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-09 02:39:40', '2026-04-09 02:39:40'),
(20, 3, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-08 21:49:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-09 02:45:56', '2026-04-09 02:45:56'),
(21, 3, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-08 22:40:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-09 03:36:37', '2026-04-09 03:36:37'),
(22, 3, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-08 22:03:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-09 03:57:35', '2026-04-09 03:57:35'),
(23, 4, NULL, NULL, 'regular', 1, NULL, NULL, 1, 1, NULL, '2026-04-08 23:04:00', 90, 14, 'published', 'auto_by_capacity', 'versus', 2, 7, 0, 1, 1, 0, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-04-09 03:59:03', '2026-04-09 03:59:03');

-- --------------------------------------------------------

--
-- Table structure for table `group_pichanga_comments`
--

CREATE TABLE `group_pichanga_comments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `post_id` bigint(20) UNSIGNED NOT NULL,
  `pichanga_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `content` varchar(500) NOT NULL,
  `status` enum('active','removed') NOT NULL DEFAULT 'active',
  `removed_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `removed_reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `group_pichanga_external_requests`
--

CREATE TABLE `group_pichanga_external_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pichanga_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('pending','accepted','rejected','expired') NOT NULL DEFAULT 'pending',
  `origin_degree` tinyint(3) UNSIGNED DEFAULT NULL,
  `relation_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `decided_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `requested_at` datetime DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `group_pichanga_notification_batches`
--

CREATE TABLE `group_pichanga_notification_batches` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pichanga_id` bigint(20) UNSIGNED NOT NULL,
  `triggered_by_user_id` bigint(20) UNSIGNED NOT NULL,
  `batch_type` enum('initial','manual_renotify','auto_48h','auto_24h') NOT NULL DEFAULT 'manual_renotify',
  `target_degree` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `filters_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`filters_json`)),
  `target_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `muted_skipped_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `sent_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `group_pichanga_notification_batches`
--

INSERT INTO `group_pichanga_notification_batches` (`id`, `pichanga_id`, `triggered_by_user_id`, `batch_type`, `target_degree`, `filters_json`, `target_count`, `muted_skipped_count`, `sent_count`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":14,\"audience_age_max\":80,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-03-29 08:36:09', '2026-03-29 08:36:09'),
(2, 2, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-03-29 10:12:29', '2026-03-29 10:12:29'),
(3, 3, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-03-29 14:47:11', '2026-03-29 14:47:11'),
(4, 4, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-03-29 17:10:54', '2026-03-29 17:10:54'),
(5, 1, 1, 'manual_renotify', 2, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 25, 0, 25, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(6, 2, 1, 'manual_renotify', 2, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 25, 0, 25, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(7, 5, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-05 00:53:04', '2026-04-05 00:53:04'),
(8, 6, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-05 00:57:30', '2026-04-05 00:57:30'),
(9, 7, 1, 'manual_renotify', 2, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 25, 0, 25, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(10, 8, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-07 17:45:46', '2026-04-07 17:45:46'),
(11, 9, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-07 18:42:37', '2026-04-07 18:42:37'),
(12, 10, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-07 18:44:03', '2026-04-07 18:44:03'),
(13, 11, 38, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 1, 0, 1, '2026-04-07 20:06:19', '2026-04-07 20:06:19'),
(14, 12, 38, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-08 01:47:27', '2026-04-08 01:47:27'),
(15, 13, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-08 07:16:28', '2026-04-08 07:16:28'),
(16, 14, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-08 07:17:55', '2026-04-08 07:17:55'),
(17, 15, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-08 16:24:33', '2026-04-08 16:24:33'),
(18, 16, 38, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-08 19:31:28', '2026-04-08 19:31:28'),
(19, 17, 38, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-08 21:12:47', '2026-04-08 21:12:47'),
(20, 18, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-08 23:56:37', '2026-04-08 23:56:37'),
(21, 19, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-09 02:39:40', '2026-04-09 02:39:40'),
(22, 20, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-09 02:45:56', '2026-04-09 02:45:56'),
(23, 21, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-09 03:36:37', '2026-04-09 03:36:37'),
(24, 22, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-09 03:57:35', '2026-04-09 03:57:35'),
(25, 23, 1, 'initial', 1, '{\"audience_sex\":null,\"audience_age_min\":null,\"audience_age_max\":null,\"skill_fisico_min\":null,\"skill_arquero_min\":null,\"skill_delantero_min\":null,\"skill_mediocampo_min\":null,\"skill_defensa_min\":null}', 2, 0, 2, '2026-04-09 03:59:03', '2026-04-09 03:59:03');

-- --------------------------------------------------------

--
-- Table structure for table `group_pichanga_participants`
--

CREATE TABLE `group_pichanga_participants` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pichanga_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `origin` enum('member','external') NOT NULL DEFAULT 'member',
  `status` enum('confirmed','withdrawn','removed') NOT NULL DEFAULT 'confirmed',
  `team_code` char(1) DEFAULT NULL,
  `team_slot` smallint(5) UNSIGNED DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `withdrawn_at` datetime DEFAULT NULL,
  `removed_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `group_pichanga_participants`
--

INSERT INTO `group_pichanga_participants` (`id`, `pichanga_id`, `user_id`, `origin`, `status`, `team_code`, `team_slot`, `confirmed_at`, `withdrawn_at`, `removed_by_user_id`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'member', 'confirmed', 'B', 1, '2026-03-30 02:47:18', NULL, NULL, '2026-03-29 08:36:09', '2026-04-07 22:23:03'),
(2, 1, 38, 'member', 'confirmed', 'A', 1, '2026-03-29 03:37:30', NULL, NULL, '2026-03-29 08:37:30', '2026-04-07 22:23:03'),
(3, 2, 1, 'member', 'confirmed', 'A', 1, '2026-03-29 05:12:29', NULL, NULL, '2026-03-29 10:12:29', '2026-04-07 22:23:03'),
(4, 2, 38, 'member', 'confirmed', 'B', 1, '2026-03-29 05:13:56', NULL, NULL, '2026-03-29 10:13:56', '2026-04-07 22:23:03'),
(5, 3, 1, 'member', 'confirmed', 'B', 1, '2026-03-30 02:47:46', NULL, NULL, '2026-03-29 14:47:11', '2026-04-07 22:23:03'),
(6, 3, 38, 'member', 'confirmed', 'A', 1, '2026-03-29 09:47:41', NULL, NULL, '2026-03-29 14:47:41', '2026-04-07 22:23:03'),
(7, 4, 1, 'member', 'confirmed', 'A', 1, '2026-03-29 12:10:54', NULL, NULL, '2026-03-29 17:10:54', '2026-04-07 22:23:03'),
(8, 4, 38, 'member', 'confirmed', 'B', 1, '2026-03-30 16:21:18', NULL, NULL, '2026-03-30 21:21:18', '2026-04-07 22:23:03'),
(9, 6, 1, 'member', 'confirmed', 'A', 1, '2026-04-04 19:57:50', NULL, NULL, '2026-04-05 00:57:50', '2026-04-07 22:23:03'),
(10, 5, 1, 'member', 'confirmed', 'A', 1, '2026-04-05 00:07:27', NULL, NULL, '2026-04-05 05:07:27', '2026-04-07 22:23:03'),
(11, 7, 1, 'member', 'confirmed', 'A', 1, '2026-04-05 00:43:01', NULL, NULL, '2026-04-05 05:43:01', '2026-04-07 22:23:03'),
(12, 7, 38, 'member', 'confirmed', 'B', 1, '2026-04-05 00:43:19', NULL, NULL, '2026-04-05 05:43:19', '2026-04-07 22:23:03'),
(13, 5, 38, 'member', 'confirmed', 'B', 1, '2026-04-05 12:19:37', NULL, NULL, '2026-04-05 17:19:37', '2026-04-07 22:23:03'),
(14, 8, 1, 'member', 'confirmed', 'A', 1, '2026-04-07 12:47:25', NULL, NULL, '2026-04-07 17:47:25', '2026-04-07 22:23:03'),
(15, 10, 1, 'member', 'confirmed', 'A', 1, '2026-04-07 13:44:14', NULL, NULL, '2026-04-07 18:44:14', '2026-04-07 22:23:03'),
(16, 12, 1, 'member', 'confirmed', 'B', 1, '2026-04-07 20:48:30', NULL, NULL, '2026-04-08 01:48:30', '2026-04-08 01:48:30'),
(17, 6, 38, 'member', 'confirmed', 'A', 2, '2026-04-08 01:51:23', NULL, NULL, '2026-04-08 06:51:23', '2026-04-08 06:51:23'),
(18, 11, 38, 'member', 'confirmed', 'A', 1, '2026-04-08 01:53:23', NULL, NULL, '2026-04-08 06:53:23', '2026-04-08 06:53:23'),
(19, 13, 1, 'member', 'confirmed', 'A', 1, '2026-04-08 02:16:51', NULL, NULL, '2026-04-08 07:16:51', '2026-04-08 07:16:51'),
(20, 13, 38, 'member', 'confirmed', 'A', 2, '2026-04-08 02:18:43', NULL, NULL, '2026-04-08 07:18:43', '2026-04-08 07:18:43'),
(21, 15, 1, 'member', 'confirmed', 'A', 1, '2026-04-08 11:25:03', NULL, NULL, '2026-04-08 16:25:03', '2026-04-08 16:25:03'),
(22, 15, 38, 'member', 'confirmed', 'B', 1, '2026-04-08 11:26:07', NULL, NULL, '2026-04-08 16:26:07', '2026-04-08 16:26:07'),
(23, 16, 1, 'member', 'confirmed', 'B', 1, '2026-04-08 14:32:30', NULL, NULL, '2026-04-08 19:32:30', '2026-04-08 19:32:30'),
(24, 17, 1, 'member', 'confirmed', 'A', 1, '2026-04-08 16:13:01', NULL, NULL, '2026-04-08 21:13:01', '2026-04-08 21:13:01'),
(25, 18, 1, 'member', 'confirmed', 'B', 1, '2026-04-08 18:57:09', NULL, NULL, '2026-04-08 23:57:09', '2026-04-08 23:57:09'),
(26, 19, 1, 'member', 'confirmed', 'B', 1, '2026-04-08 21:40:40', NULL, NULL, '2026-04-09 02:40:40', '2026-04-09 02:40:40'),
(27, 20, 1, 'member', 'confirmed', 'B', 1, '2026-04-08 21:46:12', NULL, NULL, '2026-04-09 02:46:12', '2026-04-09 02:46:12'),
(28, 21, 1, 'member', 'confirmed', 'B', 1, '2026-04-08 22:37:01', NULL, NULL, '2026-04-09 03:37:01', '2026-04-09 03:37:01'),
(29, 23, 1, 'member', 'confirmed', 'B', 1, '2026-04-08 22:59:27', NULL, NULL, '2026-04-09 03:59:27', '2026-04-09 03:59:27');

-- --------------------------------------------------------

--
-- Table structure for table `group_pichanga_posts`
--

CREATE TABLE `group_pichanga_posts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pichanga_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `post_type` enum('text','photo') NOT NULL DEFAULT 'text',
  `content` varchar(500) DEFAULT NULL,
  `photo_url` varchar(500) DEFAULT NULL,
  `status` enum('active','removed') NOT NULL DEFAULT 'active',
  `removed_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `removed_reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `group_pichanga_ratings`
--

CREATE TABLE `group_pichanga_ratings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pichanga_id` bigint(20) UNSIGNED NOT NULL,
  `rater_user_id` bigint(20) UNSIGNED NOT NULL,
  `rated_user_id` bigint(20) UNSIGNED NOT NULL,
  `fisico` decimal(3,1) NOT NULL,
  `arquero` decimal(3,1) NOT NULL,
  `delantero` decimal(3,1) NOT NULL,
  `mediocampo` decimal(3,1) NOT NULL,
  `defensa` decimal(3,1) NOT NULL,
  `comentario` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `historial_calificacion`
--

CREATE TABLE `historial_calificacion` (
  `id` int(11) NOT NULL,
  `id_user_jugador` bigint(20) UNSIGNED DEFAULT NULL,
  `id_pichanga` int(11) DEFAULT NULL COMMENT 'en caso sea luego de la pichanga',
  `posicion` varchar(5) DEFAULT NULL COMMENT 'arquero,\r\ndefensa,\r\nmedio,\r\ndelantero',
  `puntaje` decimal(3,1) DEFAULT NULL COMMENT '0.0 - 10.0',
  `comentario` varchar(500) DEFAULT NULL,
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `horario_atencion`
--

CREATE TABLE `horario_atencion` (
  `id` int(11) NOT NULL,
  `id_polideportivo` int(11) DEFAULT NULL,
  `hora_inicio` time DEFAULT NULL,
  `hora_fin` time DEFAULT NULL,
  `dia` varchar(5) DEFAULT NULL,
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `pais`
--

CREATE TABLE `pais` (
  `id` int(11) NOT NULL,
  `nombre` varchar(200) DEFAULT NULL,
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `perfil`
--

CREATE TABLE `perfil` (
  `id` int(11) NOT NULL,
  `nombre` varchar(250) DEFAULT NULL COMMENT 'Admin plataforma,\r\nAdmin polideportivo,\r\nJugador normal',
  `descripcion` varchar(250) DEFAULT NULL,
  `estado` varchar(2) DEFAULT NULL COMMENT '0,1',
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `perfil`
--

INSERT INTO `perfil` (`id`, `nombre`, `descripcion`, `estado`, `id_user_create`, `created_at`, `updated_at`) VALUES
(1, 'superadmin', 'Acceso total a clubs, usuarios y canchas', '1', 1, NULL, NULL),
(2, 'pichanguero', 'Usuario base que participa en clubs', '1', 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(1, 'App\\Models\\User', 38, 'flutter-app', '254b784ff79ccd009cc6a8a7799cc6e2031fe543fc81e6d4a81a7258b488445e', '[\"*\"]', NULL, NULL, '2026-03-24 20:37:42', '2026-03-24 20:37:42'),
(3, 'App\\Models\\User', 1, 'flutter-app', '71c0b0a3de3a0e667affc8137a8d5dfa5e005b16e430d2ec5cee7829625ed4c8', '[\"*\"]', '2026-04-07 17:20:21', NULL, '2026-03-24 23:14:08', '2026-04-07 17:20:21'),
(4, 'App\\Models\\User', 1, 'flutter-app', 'a72cedf57627f5c511d0e8fb87aeddf91e90145c29c6927d4c98a3058c145ee8', '[\"*\"]', '2026-03-25 03:55:58', NULL, '2026-03-25 01:29:49', '2026-03-25 03:55:58'),
(15, 'App\\Models\\User', 38, 'flutter-app', '89fc0b7bed88c5143701ceb3ec97386943438a1cfd391092fafbaf51dc655d4a', '[\"*\"]', '2026-04-08 21:12:56', NULL, '2026-04-02 04:45:33', '2026-04-08 21:12:56'),
(16, 'App\\Models\\User', 1, 'flutter-app', '506a388417de28f3fbb2a5af8c193af2bf33fc41d872e78d12af89ccefc43178', '[\"*\"]', '2026-04-05 05:06:52', NULL, '2026-04-05 00:44:50', '2026-04-05 05:06:52'),
(19, 'App\\Models\\User', 1, 'flutter-app', '888634ad058f7c3cf94753caa38387e69acefba752d7b92b80ec6505607f6d10', '[\"*\"]', '2026-04-09 00:02:59', NULL, '2026-04-05 23:19:55', '2026-04-09 00:02:59'),
(21, 'App\\Models\\User', 38, 'flutter-app', 'abe677ef560d5ae24f3cc801c13f06b488d8ff100902954b8c826ddd8c1dedbb', '[\"*\"]', '2026-04-08 17:54:35', NULL, '2026-04-08 04:11:53', '2026-04-08 17:54:35'),
(22, 'App\\Models\\User', 1, 'flutter-app', 'b112e9abf5e6b4dc77bd0f8e1d169f95e32d04601f9d1358069d27d5b7014f8d', '[\"*\"]', '2026-04-09 04:07:29', NULL, '2026-04-09 00:02:26', '2026-04-09 04:07:29');

-- --------------------------------------------------------

--
-- Table structure for table `pichanga`
--

CREATE TABLE `pichanga` (
  `id` int(11) NOT NULL,
  `id_evento` int(11) DEFAULT NULL,
  `id_user_asistente` bigint(20) UNSIGNED DEFAULT NULL,
  `id_equipo` int(11) DEFAULT NULL,
  `id_posicion` int(11) DEFAULT NULL,
  `nro_orden_portero` varchar(2) DEFAULT NULL,
  `hora_inicio_pichanga` time(5) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `polideportivo`
--

CREATE TABLE `polideportivo` (
  `id` int(11) NOT NULL,
  `nombre` varchar(250) DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `x` varchar(400) DEFAULT NULL,
  `y` varchar(400) DEFAULT NULL,
  `celular` varchar(10) DEFAULT NULL,
  `wsp` varchar(2) DEFAULT NULL COMMENT 'tiene wsp? 0,1',
  `id_distrito` int(11) DEFAULT NULL,
  `descripcion` varchar(300) DEFAULT NULL,
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `precio_desde` varchar(10) DEFAULT NULL,
  `precio_desde_num` decimal(10,2) DEFAULT NULL,
  `url_foto` varchar(300) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `polideportivo`
--

INSERT INTO `polideportivo` (`id`, `nombre`, `direccion`, `x`, `y`, `celular`, `wsp`, `id_distrito`, `descripcion`, `id_user_create`, `precio_desde`, `precio_desde_num`, `url_foto`, `created_at`, `updated_at`) VALUES
(1, 'Fulbii Demo Centro', 'Av. Nicolas de Pierola 123, Lima', '-12.046400', '-77.042800', '999111222', '1', NULL, 'Cancha demo para validar mapa y flujo de pichangas.', 1, '50', '50.00', NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(2, 'Fulbii Demo Miraflores', 'Av. Larco 350, Miraflores', '-12.121300', '-77.029700', '999222333', '1', NULL, 'Cancha con tribuna y estacionamiento.', 1, '70', '70.00', NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(3, 'Fulbii Demo Surquillo', 'Av. Angamos 456, Surquillo', '-12.111100', '-77.021500', '999333444', '1', NULL, 'Cancha rápida para retos 5v5.', 1, '45', '45.00', NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19'),
(4, 'Fulbii Demo Los Olivos', 'Av. Universitaria 789, Los Olivos', '-11.996000', '-77.070000', '999444555', '0', NULL, 'Cancha económica para partidos nocturnos.', 1, '40', '40.00', NULL, '2026-03-29 08:12:19', '2026-03-29 08:12:19');

-- --------------------------------------------------------

--
-- Table structure for table `posicion`
--

CREATE TABLE `posicion` (
  `id` int(11) NOT NULL,
  `id_formacion` int(11) DEFAULT NULL,
  `posicion` varchar(5) DEFAULT NULL COMMENT 'arquero,\r\ndefensa,\r\nmedio,\r\ndelantero',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `product_events`
--

CREATE TABLE `product_events` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `event_name` varchar(80) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `club_id` bigint(20) UNSIGNED DEFAULT NULL,
  `pichanga_id` bigint(20) UNSIGNED DEFAULT NULL,
  `source` varchar(40) NOT NULL DEFAULT 'api',
  `metadata_json` longtext DEFAULT NULL,
  `happened_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `product_events`
--

INSERT INTO `product_events` (`id`, `event_name`, `user_id`, `club_id`, `pichanga_id`, `source`, `metadata_json`, `happened_at`, `created_at`, `updated_at`) VALUES
(1, 'auth_social_login_success', 38, NULL, NULL, 'auth', '{\"provider\":\"apple\",\"needs_onboarding\":true,\"trusted_mode\":false}', '2026-03-24 15:48:48', '2026-03-24 20:48:48', '2026-03-24 20:48:48'),
(2, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":true,\"trusted_mode\":false}', '2026-03-24 18:14:08', '2026-03-24 23:14:08', '2026-03-24 23:14:08'),
(3, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-24 20:29:49', '2026-03-25 01:29:49', '2026-03-25 01:29:49'),
(4, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-29 02:49:46', '2026-03-29 07:49:46', '2026-03-29 07:49:46'),
(5, 'auth_social_login_success', 38, NULL, NULL, 'auth', '{\"provider\":\"apple\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-29 02:50:37', '2026-03-29 07:50:37', '2026-03-29 07:50:37'),
(6, 'club_join_request_created', 1, 3, NULL, 'api', '{\"request_id\":1,\"requested_via\":\"search\"}', '2026-03-29 02:51:37', '2026-03-29 07:51:37', '2026-03-29 07:51:37'),
(7, 'club_join_request_rejected', 38, 3, NULL, 'api', '{\"request_id\":1,\"requester_user_id\":1}', '2026-03-29 02:52:23', '2026-03-29 07:52:23', '2026-03-29 07:52:23'),
(8, 'club_join_request_created', 1, 3, NULL, 'api', '{\"request_id\":2,\"requested_via\":\"search\"}', '2026-03-29 02:52:44', '2026-03-29 07:52:44', '2026-03-29 07:52:44'),
(9, 'club_join_request_rejected', 38, 3, NULL, 'api', '{\"request_id\":2,\"requester_user_id\":1}', '2026-03-29 02:52:56', '2026-03-29 07:52:56', '2026-03-29 07:52:56'),
(10, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-29 03:05:52', '2026-03-29 08:05:52', '2026-03-29 08:05:52'),
(11, 'club_join_request_created', 1, 3, NULL, 'api', '{\"request_id\":3,\"requested_via\":\"search\"}', '2026-03-29 03:33:02', '2026-03-29 08:33:02', '2026-03-29 08:33:02'),
(12, 'club_join_request_rejected', 38, 3, NULL, 'api', '{\"request_id\":3,\"requester_user_id\":1}', '2026-03-29 03:33:12', '2026-03-29 08:33:12', '2026-03-29 08:33:12'),
(13, 'club_join_request_created', 1, 3, NULL, 'api', '{\"request_id\":4,\"requested_via\":\"search\"}', '2026-03-29 03:33:21', '2026-03-29 08:33:21', '2026-03-29 08:33:21'),
(14, 'club_join_request_created', 38, 4, NULL, 'api', '{\"request_id\":5,\"requested_via\":\"search\"}', '2026-03-29 03:34:21', '2026-03-29 08:34:21', '2026-03-29 08:34:21'),
(15, 'club_join_request_accepted', 1, 4, NULL, 'api', '{\"request_id\":5,\"requester_user_id\":38}', '2026-03-29 03:34:39', '2026-03-29 08:34:39', '2026-03-29 08:34:39'),
(16, 'pichanga_created', 1, 4, 1, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-03-29 03:36:09', '2026-03-29 08:36:09', '2026-03-29 08:36:09'),
(17, 'pichanga_confirmed', 1, 4, 1, 'api', NULL, '2026-03-29 03:36:43', '2026-03-29 08:36:43', '2026-03-29 08:36:43'),
(18, 'pichanga_confirmed', 1, 4, 1, 'api', NULL, '2026-03-29 03:37:15', '2026-03-29 08:37:15', '2026-03-29 08:37:15'),
(19, 'pichanga_confirmed', 38, 4, 1, 'api', NULL, '2026-03-29 03:37:30', '2026-03-29 08:37:30', '2026-03-29 08:37:30'),
(20, 'pichanga_created', 1, 4, 2, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-03-29 05:12:29', '2026-03-29 10:12:29', '2026-03-29 10:12:29'),
(21, 'pichanga_confirmed', 38, 4, 2, 'api', NULL, '2026-03-29 05:13:56', '2026-03-29 10:13:56', '2026-03-29 10:13:56'),
(22, 'pichanga_created', 1, 4, 3, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-03-29 09:47:11', '2026-03-29 14:47:11', '2026-03-29 14:47:11'),
(23, 'pichanga_confirmed', 38, 4, 3, 'api', NULL, '2026-03-29 09:47:41', '2026-03-29 14:47:41', '2026-03-29 14:47:41'),
(24, 'pichanga_confirmed', 1, 4, 3, 'api', NULL, '2026-03-29 09:47:57', '2026-03-29 14:47:57', '2026-03-29 14:47:57'),
(25, 'auth_social_login_success', 38, NULL, NULL, 'auth', '{\"provider\":\"apple\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-29 10:01:12', '2026-03-29 15:01:12', '2026-03-29 15:01:12'),
(26, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-29 10:01:45', '2026-03-29 15:01:45', '2026-03-29 15:01:45'),
(27, 'pichanga_created', 1, 4, 4, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-03-29 12:10:54', '2026-03-29 17:10:54', '2026-03-29 17:10:54'),
(28, 'pichanga_withdrawn', 1, 4, 4, 'api', NULL, '2026-03-29 12:12:51', '2026-03-29 17:12:51', '2026-03-29 17:12:51'),
(29, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-29 12:51:36', '2026-03-29 17:51:36', '2026-03-29 17:51:36'),
(30, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-30 00:55:24', '2026-03-30 05:55:24', '2026-03-30 05:55:24'),
(31, 'auth_social_login_success', 38, NULL, NULL, 'auth', '{\"provider\":\"apple\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-30 01:04:54', '2026-03-30 06:04:54', '2026-03-30 06:04:54'),
(32, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-03-30 01:05:10', '2026-03-30 06:05:10', '2026-03-30 06:05:10'),
(33, 'pichanga_renotify_sent', 1, 4, 1, 'api', '{\"target_count\":25,\"sent_count\":25,\"muted_skipped_count\":0,\"target_degree\":2}', '2026-03-30 02:46:02', '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(34, 'pichanga_confirmed', 1, 4, 1, 'api', NULL, '2026-03-30 02:47:18', '2026-03-30 07:47:18', '2026-03-30 07:47:18'),
(35, 'pichanga_confirmed', 1, 4, 3, 'api', NULL, '2026-03-30 02:47:46', '2026-03-30 07:47:46', '2026-03-30 07:47:46'),
(36, 'pichanga_confirmed', 1, 4, 4, 'api', '{\"team_code\":\"A\"}', '2026-03-30 16:18:38', '2026-03-30 21:18:38', '2026-03-30 21:18:38'),
(37, 'pichanga_confirmed', 38, 4, 4, 'api', '{\"team_code\":\"B\"}', '2026-03-30 16:21:18', '2026-03-30 21:21:18', '2026-03-30 21:21:18'),
(38, 'pichanga_renotify_sent', 1, 4, 2, 'api', '{\"target_count\":25,\"sent_count\":25,\"muted_skipped_count\":0,\"target_degree\":2}', '2026-03-30 18:40:08', '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(39, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-04-01 19:57:02', '2026-04-02 00:57:02', '2026-04-02 00:57:02'),
(40, 'auth_social_login_success', 38, NULL, NULL, 'auth', '{\"provider\":\"apple\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-04-01 23:45:33', '2026-04-02 04:45:33', '2026-04-02 04:45:33'),
(41, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-04-04 19:44:50', '2026-04-05 00:44:50', '2026-04-05 00:44:50'),
(42, 'pichanga_created', 1, 4, 5, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-04 19:53:04', '2026-04-05 00:53:04', '2026-04-05 00:53:04'),
(43, 'pichanga_created', 1, 4, 6, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-04 19:57:30', '2026-04-05 00:57:30', '2026-04-05 00:57:30'),
(44, 'pichanga_confirmed', 1, 4, 6, 'api', '{\"team_code\":\"B\"}', '2026-04-04 19:57:50', '2026-04-05 00:57:50', '2026-04-05 00:57:50'),
(45, 'pichanga_confirmed', 1, 4, 6, 'api', '{\"team_code\":\"B\"}', '2026-04-04 19:57:54', '2026-04-05 00:57:54', '2026-04-05 00:57:54'),
(46, 'pichanga_confirmed', 1, 4, 6, 'api', '{\"team_code\":\"B\"}', '2026-04-04 19:58:06', '2026-04-05 00:58:06', '2026-04-05 00:58:06'),
(47, 'pichanga_confirmed', 1, 4, 6, 'api', '{\"team_code\":\"B\"}', '2026-04-04 19:58:29', '2026-04-05 00:58:29', '2026-04-05 00:58:29'),
(48, 'pichanga_confirmed', 1, 4, 6, 'api', '{\"team_code\":\"A\"}', '2026-04-05 00:06:08', '2026-04-05 05:06:08', '2026-04-05 05:06:08'),
(49, 'pichanga_confirmed', 1, 4, 6, 'api', '{\"team_code\":\"A\"}', '2026-04-05 00:06:19', '2026-04-05 05:06:19', '2026-04-05 05:06:19'),
(50, 'pichanga_confirmed', 1, 4, 6, 'api', '{\"team_code\":\"B\"}', '2026-04-05 00:06:22', '2026-04-05 05:06:22', '2026-04-05 05:06:22'),
(51, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-04-05 00:07:05', '2026-04-05 05:07:05', '2026-04-05 05:07:05'),
(52, 'pichanga_confirmed', 1, 4, 6, 'api', '{\"team_code\":\"B\"}', '2026-04-05 00:07:16', '2026-04-05 05:07:16', '2026-04-05 05:07:16'),
(53, 'pichanga_confirmed', 1, 4, 5, 'api', '{\"team_code\":\"B\"}', '2026-04-05 00:07:27', '2026-04-05 05:07:27', '2026-04-05 05:07:27'),
(54, 'challenge_created', 1, 4, NULL, 'api', '{\"challenge_id\":1,\"challenged_club_id\":3,\"team_size\":6,\"notify_sent_count\":1}', '2026-04-05 00:34:40', '2026-04-05 05:34:40', '2026-04-05 05:34:40'),
(55, 'challenge_coordinator_set', 38, 4, NULL, 'api', '{\"challenge_id\":1,\"side\":\"challenger\",\"sent_count\":1}', '2026-04-05 00:37:03', '2026-04-05 05:37:03', '2026-04-05 05:37:03'),
(56, 'challenge_chat_message', 1, 4, NULL, 'api', '{\"challenge_id\":1,\"message_id\":3,\"sent_count\":0,\"active_chat_skipped_count\":1}', '2026-04-05 00:37:19', '2026-04-05 05:37:19', '2026-04-05 05:37:19'),
(57, 'challenge_chat_message', 1, 4, NULL, 'api', '{\"challenge_id\":1,\"message_id\":4,\"sent_count\":0,\"active_chat_skipped_count\":1}', '2026-04-05 00:37:30', '2026-04-05 05:37:30', '2026-04-05 05:37:30'),
(58, 'challenge_chat_message', 1, 4, NULL, 'api', '{\"challenge_id\":1,\"message_id\":5,\"sent_count\":0,\"active_chat_skipped_count\":1}', '2026-04-05 00:38:35', '2026-04-05 05:38:35', '2026-04-05 05:38:35'),
(59, 'challenge_chat_message', 1, 4, NULL, 'api', '{\"challenge_id\":1,\"message_id\":6,\"sent_count\":0,\"active_chat_skipped_count\":1}', '2026-04-05 00:38:43', '2026-04-05 05:38:43', '2026-04-05 05:38:43'),
(60, 'challenge_coordinator_set', 38, 4, NULL, 'api', '{\"challenge_id\":1,\"side\":\"challenger\",\"sent_count\":1}', '2026-04-05 00:39:09', '2026-04-05 05:39:09', '2026-04-05 05:39:09'),
(61, 'challenge_chat_message', 1, 4, NULL, 'api', '{\"challenge_id\":1,\"message_id\":10,\"sent_count\":0,\"active_chat_skipped_count\":1}', '2026-04-05 00:41:10', '2026-04-05 05:41:10', '2026-04-05 05:41:10'),
(62, 'challenge_chat_message', 1, 4, NULL, 'api', '{\"challenge_id\":1,\"message_id\":11,\"sent_count\":0,\"active_chat_skipped_count\":1}', '2026-04-05 00:41:13', '2026-04-05 05:41:13', '2026-04-05 05:41:13'),
(63, 'challenge_coordinator_set', 1, 4, NULL, 'api', '{\"challenge_id\":1,\"side\":\"challenger\",\"sent_count\":1}', '2026-04-05 00:42:09', '2026-04-05 05:42:09', '2026-04-05 05:42:09'),
(64, 'challenge_confirmed', 1, 4, 7, 'api', '{\"challenge_id\":1,\"configuration_id\":1,\"sent_count\":1}', '2026-04-05 00:42:14', '2026-04-05 05:42:14', '2026-04-05 05:42:14'),
(65, 'pichanga_confirmed', 1, 4, 7, 'api', '{\"team_code\":\"A\"}', '2026-04-05 00:43:01', '2026-04-05 05:43:01', '2026-04-05 05:43:01'),
(66, 'pichanga_confirmed', 38, 4, 7, 'api', '{\"team_code\":\"B\"}', '2026-04-05 00:43:19', '2026-04-05 05:43:19', '2026-04-05 05:43:19'),
(67, 'pichanga_confirmed', 38, 4, 5, 'api', '{\"team_code\":\"B\"}', '2026-04-05 12:19:37', '2026-04-05 17:19:37', '2026-04-05 17:19:37'),
(68, 'pichanga_renotify_sent', 1, 4, 7, 'api', '{\"target_count\":25,\"sent_count\":25,\"muted_skipped_count\":0,\"target_degree\":2}', '2026-04-05 12:23:37', '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(69, 'auth_social_login_success', 39, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":true,\"trusted_mode\":false}', '2026-04-05 18:09:51', '2026-04-05 23:09:51', '2026-04-05 23:09:51'),
(70, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-04-05 18:19:55', '2026-04-05 23:19:55', '2026-04-05 23:19:55'),
(71, 'pichanga_created', 1, 4, 8, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-07 12:45:46', '2026-04-07 17:45:46', '2026-04-07 17:45:46'),
(72, 'pichanga_confirmed', 1, 4, 8, 'api', '{\"team_code\":\"A\"}', '2026-04-07 12:47:25', '2026-04-07 17:47:25', '2026-04-07 17:47:25'),
(73, 'pichanga_created', 1, 4, 9, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-07 13:42:37', '2026-04-07 18:42:37', '2026-04-07 18:42:37'),
(74, 'pichanga_created', 1, 4, 10, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-07 13:44:03', '2026-04-07 18:44:03', '2026-04-07 18:44:03'),
(75, 'pichanga_confirmed', 1, 4, 10, 'api', '{\"team_code\":\"A\"}', '2026-04-07 13:44:14', '2026-04-07 18:44:14', '2026-04-07 18:44:14'),
(76, 'pichanga_created', 38, 3, 11, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-07 15:06:19', '2026-04-07 20:06:19', '2026-04-07 20:06:19'),
(77, 'club_join_request_accepted', 38, 3, NULL, 'api', '{\"request_id\":4,\"requester_user_id\":1}', '2026-04-07 15:08:04', '2026-04-07 20:08:04', '2026-04-07 20:08:04'),
(78, 'pichanga_created', 38, 3, 12, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-07 20:47:27', '2026-04-08 01:47:27', '2026-04-08 01:47:27'),
(79, 'pichanga_confirmed', 1, 3, 12, 'api', '{\"team_code\":\"B\"}', '2026-04-07 20:48:30', '2026-04-08 01:48:30', '2026-04-08 01:48:30'),
(80, 'auth_social_login_success', 38, NULL, NULL, 'auth', '{\"provider\":\"apple\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-04-07 22:28:46', '2026-04-08 03:28:46', '2026-04-08 03:28:46'),
(81, 'auth_social_login_success', 38, NULL, NULL, 'auth', '{\"provider\":\"apple\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-04-07 23:11:53', '2026-04-08 04:11:53', '2026-04-08 04:11:53'),
(82, 'pichanga_confirmed', 38, 4, 6, 'api', '{\"team_code\":\"A\"}', '2026-04-08 01:51:23', '2026-04-08 06:51:23', '2026-04-08 06:51:23'),
(83, 'pichanga_confirmed', 38, 3, 11, 'api', '{\"team_code\":\"A\"}', '2026-04-08 01:53:23', '2026-04-08 06:53:23', '2026-04-08 06:53:23'),
(84, 'pichanga_created', 1, 3, 13, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 02:16:28', '2026-04-08 07:16:28', '2026-04-08 07:16:28'),
(85, 'pichanga_confirmed', 1, 3, 13, 'api', '{\"team_code\":\"A\"}', '2026-04-08 02:16:51', '2026-04-08 07:16:51', '2026-04-08 07:16:51'),
(86, 'pichanga_created', 1, 3, 14, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 02:17:55', '2026-04-08 07:17:55', '2026-04-08 07:17:55'),
(87, 'pichanga_confirmed', 38, 3, 13, 'api', '{\"team_code\":\"A\"}', '2026-04-08 02:18:43', '2026-04-08 07:18:43', '2026-04-08 07:18:43'),
(88, 'pichanga_created', 1, 3, 15, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 11:24:33', '2026-04-08 16:24:33', '2026-04-08 16:24:33'),
(89, 'pichanga_confirmed', 1, 3, 15, 'api', '{\"team_code\":\"A\"}', '2026-04-08 11:25:03', '2026-04-08 16:25:03', '2026-04-08 16:25:03'),
(90, 'pichanga_confirmed', 38, 3, 15, 'api', '{\"team_code\":\"B\"}', '2026-04-08 11:26:08', '2026-04-08 16:26:08', '2026-04-08 16:26:08'),
(91, 'pichanga_created', 38, 3, 16, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 14:31:28', '2026-04-08 19:31:28', '2026-04-08 19:31:28'),
(92, 'pichanga_confirmed', 1, 3, 16, 'api', '{\"team_code\":\"B\"}', '2026-04-08 14:32:30', '2026-04-08 19:32:30', '2026-04-08 19:32:30'),
(93, 'pichanga_created', 38, 3, 17, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 16:12:47', '2026-04-08 21:12:47', '2026-04-08 21:12:47'),
(94, 'pichanga_confirmed', 1, 3, 17, 'api', '{\"team_code\":\"A\"}', '2026-04-08 16:13:01', '2026-04-08 21:13:01', '2026-04-08 21:13:01'),
(95, 'pichanga_created', 1, 3, 18, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 18:56:37', '2026-04-08 23:56:37', '2026-04-08 23:56:37'),
(96, 'pichanga_confirmed', 1, 3, 18, 'api', '{\"team_code\":\"B\"}', '2026-04-08 18:57:09', '2026-04-08 23:57:09', '2026-04-08 23:57:09'),
(97, 'auth_social_login_success', 1, NULL, NULL, 'auth', '{\"provider\":\"google\",\"needs_onboarding\":false,\"trusted_mode\":false}', '2026-04-08 19:02:26', '2026-04-09 00:02:26', '2026-04-09 00:02:26'),
(98, 'pichanga_created', 1, 3, 19, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 21:39:41', '2026-04-09 02:39:41', '2026-04-09 02:39:41'),
(99, 'pichanga_confirmed', 1, 3, 19, 'api', '{\"team_code\":\"B\"}', '2026-04-08 21:40:40', '2026-04-09 02:40:40', '2026-04-09 02:40:40'),
(100, 'pichanga_created', 1, 3, 20, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 21:45:56', '2026-04-09 02:45:56', '2026-04-09 02:45:56'),
(101, 'pichanga_confirmed', 1, 3, 20, 'api', '{\"team_code\":\"B\"}', '2026-04-08 21:46:12', '2026-04-09 02:46:12', '2026-04-09 02:46:12'),
(102, 'pichanga_created', 1, 3, 21, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 22:36:37', '2026-04-09 03:36:37', '2026-04-09 03:36:37'),
(103, 'pichanga_confirmed', 1, 3, 21, 'api', '{\"team_code\":\"B\"}', '2026-04-08 22:37:01', '2026-04-09 03:37:01', '2026-04-09 03:37:01'),
(104, 'pichanga_created', 1, 3, 22, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 22:57:35', '2026-04-09 03:57:35', '2026-04-09 03:57:35'),
(105, 'pichanga_created', 1, 4, 23, 'api', '{\"notify_degree\":1,\"capacity\":14}', '2026-04-08 22:59:03', '2026-04-09 03:59:03', '2026-04-09 03:59:03'),
(106, 'pichanga_confirmed', 1, 4, 23, 'api', '{\"team_code\":\"B\"}', '2026-04-08 22:59:27', '2026-04-09 03:59:27', '2026-04-09 03:59:27');

-- --------------------------------------------------------

--
-- Table structure for table `provincia`
--

CREATE TABLE `provincia` (
  `id` int(11) NOT NULL,
  `nombres` varchar(200) DEFAULT NULL,
  `id_region` int(11) DEFAULT NULL,
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `push_dispatch_logs`
--

CREATE TABLE `push_dispatch_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `push_notification_id` bigint(20) UNSIGNED NOT NULL,
  `user_device_id` bigint(20) UNSIGNED DEFAULT NULL,
  `status` enum('queued','sent','failed') NOT NULL DEFAULT 'queued',
  `provider` varchar(30) NOT NULL DEFAULT 'log',
  `provider_response` text DEFAULT NULL,
  `error_message` varchar(255) DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `push_dispatch_logs`
--

INSERT INTO `push_dispatch_logs` (`id`, `push_notification_id`, `user_device_id`, `status`, `provider`, `provider_response`, `error_message`, `sent_at`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'failed', 'fcm', NULL, 'FCM server key no configurada.', '2026-03-29 03:36:10', '2026-03-29 08:36:10', '2026-03-29 08:36:10'),
(2, 1, 2, 'failed', 'fcm', NULL, 'FCM server key no configurada.', '2026-03-29 03:36:10', '2026-03-29 08:36:10', '2026-03-29 08:36:10'),
(3, 2, 3, 'failed', 'fcm', NULL, 'FCM server key no configurada.', '2026-03-29 03:36:10', '2026-03-29 08:36:10', '2026-03-29 08:36:10'),
(4, 3, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1774779149942008%6e6531436e653143\"\n}\n', NULL, '2026-03-29 05:12:29', '2026-03-29 10:12:29', '2026-03-29 10:12:29'),
(5, 3, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774779150137610\"\n}\n', NULL, '2026-03-29 05:12:30', '2026-03-29 10:12:29', '2026-03-29 10:12:30'),
(6, 3, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774779150479707\"\n}\n', NULL, '2026-03-29 05:12:30', '2026-03-29 10:12:30', '2026-03-29 10:12:30'),
(7, 4, 3, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774779150902617\"\n}\n', NULL, '2026-03-29 05:12:31', '2026-03-29 10:12:30', '2026-03-29 10:12:31'),
(8, 4, 5, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774779151520510\"\n}\n', NULL, '2026-03-29 05:12:31', '2026-03-29 10:12:31', '2026-03-29 10:12:31'),
(9, 5, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1774795632479619%6e6531436e653143\"\n}\n', NULL, '2026-03-29 09:47:12', '2026-03-29 14:47:12', '2026-03-29 14:47:12'),
(10, 5, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774795632871642\"\n}\n', NULL, '2026-03-29 09:47:13', '2026-03-29 14:47:12', '2026-03-29 14:47:13'),
(11, 5, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774795633397009\"\n}\n', NULL, '2026-03-29 09:47:13', '2026-03-29 14:47:13', '2026-03-29 14:47:13'),
(12, 6, 3, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774795633815711\"\n}\n', NULL, '2026-03-29 09:47:14', '2026-03-29 14:47:13', '2026-03-29 14:47:14'),
(13, 6, 5, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774795634193373\"\n}\n', NULL, '2026-03-29 09:47:14', '2026-03-29 14:47:14', '2026-03-29 14:47:14'),
(14, 7, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1774804255118728%6e6531436e653143\"\n}\n', NULL, '2026-03-29 12:10:55', '2026-03-29 17:10:54', '2026-03-29 17:10:55'),
(15, 7, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774804255338677\"\n}\n', NULL, '2026-03-29 12:10:55', '2026-03-29 17:10:55', '2026-03-29 17:10:55'),
(16, 7, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774804255694055\"\n}\n', NULL, '2026-03-29 12:10:56', '2026-03-29 17:10:55', '2026-03-29 17:10:56'),
(17, 7, 7, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774804256223692\"\n}\n', NULL, '2026-03-29 12:10:56', '2026-03-29 17:10:56', '2026-03-29 17:10:56'),
(18, 8, 3, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774804256616964\"\n}\n', NULL, '2026-03-29 12:10:56', '2026-03-29 17:10:56', '2026-03-29 17:10:56'),
(19, 8, 5, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774804257044313\"\n}\n', NULL, '2026-03-29 12:10:57', '2026-03-29 17:10:56', '2026-03-29 17:10:57'),
(20, 8, 6, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774804257385897\"\n}\n', NULL, '2026-03-29 12:10:57', '2026-03-29 17:10:57', '2026-03-29 17:10:57'),
(21, 9, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1774856763049497%6e6531436e653143\"\n}\n', NULL, '2026-03-30 02:46:03', '2026-03-30 07:46:02', '2026-03-30 07:46:03'),
(22, 9, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774856763264427\"\n}\n', NULL, '2026-03-30 02:46:03', '2026-03-30 07:46:03', '2026-03-30 07:46:03'),
(23, 9, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774856763638683\"\n}\n', NULL, '2026-03-30 02:46:03', '2026-03-30 07:46:03', '2026-03-30 07:46:03'),
(24, 9, 7, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774856763994583\"\n}\n', NULL, '2026-03-30 02:46:04', '2026-03-30 07:46:03', '2026-03-30 07:46:04'),
(25, 9, 8, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774856764285672\"\n}\n', NULL, '2026-03-30 02:46:04', '2026-03-30 07:46:04', '2026-03-30 07:46:04'),
(26, 9, 9, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774856764688900\"\n}\n', NULL, '2026-03-30 02:46:04', '2026-03-30 07:46:04', '2026-03-30 07:46:04'),
(27, 10, 3, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774856765142944\"\n}\n', NULL, '2026-03-30 02:46:05', '2026-03-30 07:46:04', '2026-03-30 07:46:05'),
(28, 10, 5, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774856765516055\"\n}\n', NULL, '2026-03-30 02:46:05', '2026-03-30 07:46:05', '2026-03-30 07:46:05'),
(29, 10, 6, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774856765852807\"\n}\n', NULL, '2026-03-30 02:46:06', '2026-03-30 07:46:05', '2026-03-30 07:46:06'),
(30, 11, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(31, 12, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(32, 13, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(33, 14, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(34, 15, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(35, 16, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(36, 17, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(37, 18, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(38, 19, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(39, 20, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(40, 21, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(41, 22, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(42, 23, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(43, 24, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(44, 25, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(45, 26, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(46, 27, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(47, 28, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(48, 29, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(49, 30, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(50, 31, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(51, 32, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(52, 33, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 07:46:06', '2026-03-30 07:46:06'),
(53, 34, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1774914009318789%6e6531436e653143\"\n}\n', NULL, '2026-03-30 18:40:09', '2026-03-30 23:40:08', '2026-03-30 23:40:09'),
(54, 34, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914009561216\"\n}\n', NULL, '2026-03-30 18:40:09', '2026-03-30 23:40:09', '2026-03-30 23:40:09'),
(55, 34, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914010098799\"\n}\n', NULL, '2026-03-30 18:40:10', '2026-03-30 23:40:09', '2026-03-30 23:40:10'),
(56, 34, 7, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914010619383\"\n}\n', NULL, '2026-03-30 18:40:10', '2026-03-30 23:40:10', '2026-03-30 23:40:10'),
(57, 34, 8, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914010994075\"\n}\n', NULL, '2026-03-30 18:40:11', '2026-03-30 23:40:10', '2026-03-30 23:40:11'),
(58, 34, 9, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914011427935\"\n}\n', NULL, '2026-03-30 18:40:11', '2026-03-30 23:40:11', '2026-03-30 23:40:11'),
(59, 34, 10, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914011784472\"\n}\n', NULL, '2026-03-30 18:40:12', '2026-03-30 23:40:11', '2026-03-30 23:40:12'),
(60, 34, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914012187126\"\n}\n', NULL, '2026-03-30 18:40:12', '2026-03-30 23:40:12', '2026-03-30 23:40:12'),
(61, 35, 3, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914012751655\"\n}\n', NULL, '2026-03-30 18:40:12', '2026-03-30 23:40:12', '2026-03-30 23:40:12'),
(62, 35, 5, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914013122703\"\n}\n', NULL, '2026-03-30 18:40:13', '2026-03-30 23:40:12', '2026-03-30 23:40:13'),
(63, 35, 6, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914013426729\"\n}\n', NULL, '2026-03-30 18:40:13', '2026-03-30 23:40:13', '2026-03-30 23:40:13'),
(64, 35, 11, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914013722970\"\n}\n', NULL, '2026-03-30 18:40:13', '2026-03-30 23:40:13', '2026-03-30 23:40:13'),
(65, 35, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1774914014178789\"\n}\n', NULL, '2026-03-30 18:40:14', '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(66, 36, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(67, 37, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(68, 38, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(69, 39, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(70, 40, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(71, 41, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(72, 42, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(73, 43, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(74, 44, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(75, 45, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(76, 46, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(77, 47, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(78, 48, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(79, 49, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(80, 50, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(81, 51, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(82, 52, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(83, 53, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(84, 54, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(85, 55, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(86, 56, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(87, 57, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(88, 58, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-03-30 23:40:14', '2026-03-30 23:40:14'),
(89, 59, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775350385676145%6e6531436e653143\"\n}\n', NULL, '2026-04-04 19:53:05', '2026-04-05 00:53:05', '2026-04-05 00:53:05'),
(90, 59, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350385915254\"\n}\n', NULL, '2026-04-04 19:53:06', '2026-04-05 00:53:05', '2026-04-05 00:53:06'),
(91, 59, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350386371811\"\n}\n', NULL, '2026-04-04 19:53:06', '2026-04-05 00:53:06', '2026-04-05 00:53:06'),
(92, 59, 7, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350386755519\"\n}\n', NULL, '2026-04-04 19:53:07', '2026-04-05 00:53:06', '2026-04-05 00:53:07'),
(93, 59, 8, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350387263905\"\n}\n', NULL, '2026-04-04 19:53:07', '2026-04-05 00:53:07', '2026-04-05 00:53:07'),
(94, 59, 9, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350387685640\"\n}\n', NULL, '2026-04-04 19:53:07', '2026-04-05 00:53:07', '2026-04-05 00:53:07'),
(95, 59, 10, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350388050607\"\n}\n', NULL, '2026-04-04 19:53:08', '2026-04-05 00:53:07', '2026-04-05 00:53:08'),
(96, 59, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350388483083\"\n}\n', NULL, '2026-04-04 19:53:08', '2026-04-05 00:53:08', '2026-04-05 00:53:08'),
(97, 60, 3, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350388990182\"\n}\n', NULL, '2026-04-04 19:53:09', '2026-04-05 00:53:08', '2026-04-05 00:53:09'),
(98, 60, 5, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350389492311\"\n}\n', NULL, '2026-04-04 19:53:09', '2026-04-05 00:53:09', '2026-04-05 00:53:09'),
(99, 60, 6, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350389895772\"\n}\n', NULL, '2026-04-04 19:53:10', '2026-04-05 00:53:09', '2026-04-05 00:53:10'),
(100, 60, 11, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350390288302\"\n}\n', NULL, '2026-04-04 19:53:10', '2026-04-05 00:53:10', '2026-04-05 00:53:10'),
(101, 60, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350390549398\"\n}\n', NULL, '2026-04-04 19:53:10', '2026-04-05 00:53:10', '2026-04-05 00:53:10'),
(102, 61, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775350651117065%6e6531436e653143\"\n}\n', NULL, '2026-04-04 19:57:31', '2026-04-05 00:57:30', '2026-04-05 00:57:31'),
(103, 61, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350651356611\"\n}\n', NULL, '2026-04-04 19:57:31', '2026-04-05 00:57:31', '2026-04-05 00:57:31'),
(104, 61, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350651630064\"\n}\n', NULL, '2026-04-04 19:57:31', '2026-04-05 00:57:31', '2026-04-05 00:57:31'),
(105, 61, 7, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350652017678\"\n}\n', NULL, '2026-04-04 19:57:32', '2026-04-05 00:57:31', '2026-04-05 00:57:32'),
(106, 61, 8, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350652524771\"\n}\n', NULL, '2026-04-04 19:57:32', '2026-04-05 00:57:32', '2026-04-05 00:57:32'),
(107, 61, 9, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350652851809\"\n}\n', NULL, '2026-04-04 19:57:33', '2026-04-05 00:57:32', '2026-04-05 00:57:33'),
(108, 61, 10, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350653403022\"\n}\n', NULL, '2026-04-04 19:57:33', '2026-04-05 00:57:33', '2026-04-05 00:57:33'),
(109, 61, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350653684782\"\n}\n', NULL, '2026-04-04 19:57:34', '2026-04-05 00:57:33', '2026-04-05 00:57:34'),
(110, 62, 3, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350654163060\"\n}\n', NULL, '2026-04-04 19:57:34', '2026-04-05 00:57:34', '2026-04-05 00:57:34'),
(111, 62, 5, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350654670541\"\n}\n', NULL, '2026-04-04 19:57:34', '2026-04-05 00:57:34', '2026-04-05 00:57:34'),
(112, 62, 6, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350654938071\"\n}\n', NULL, '2026-04-04 19:57:35', '2026-04-05 00:57:34', '2026-04-05 00:57:35'),
(113, 62, 11, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350655394490\"\n}\n', NULL, '2026-04-04 19:57:35', '2026-04-05 00:57:35', '2026-04-05 00:57:35'),
(114, 62, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775350655738846\"\n}\n', NULL, '2026-04-04 19:57:35', '2026-04-05 00:57:35', '2026-04-05 00:57:35'),
(115, 63, 3, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367281660877\"\n}\n', NULL, '2026-04-05 00:34:41', '2026-04-05 05:34:41', '2026-04-05 05:34:41'),
(116, 63, 5, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367282047069\"\n}\n', NULL, '2026-04-05 00:34:42', '2026-04-05 05:34:41', '2026-04-05 05:34:42'),
(117, 63, 6, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367282510438\"\n}\n', NULL, '2026-04-05 00:34:42', '2026-04-05 05:34:42', '2026-04-05 05:34:42'),
(118, 63, 11, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367282969915\"\n}\n', NULL, '2026-04-05 00:34:43', '2026-04-05 05:34:42', '2026-04-05 05:34:43'),
(119, 63, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367283372346\"\n}\n', NULL, '2026-04-05 00:34:43', '2026-04-05 05:34:43', '2026-04-05 05:34:43'),
(120, 64, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775367423427716%6e6531436e653143\"\n}\n', NULL, '2026-04-05 00:37:03', '2026-04-05 05:37:03', '2026-04-05 05:37:03'),
(121, 64, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367423633251\"\n}\n', NULL, '2026-04-05 00:37:03', '2026-04-05 05:37:03', '2026-04-05 05:37:03'),
(122, 64, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367423975331\"\n}\n', NULL, '2026-04-05 00:37:04', '2026-04-05 05:37:03', '2026-04-05 05:37:04'),
(123, 64, 7, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367424361391\"\n}\n', NULL, '2026-04-05 00:37:04', '2026-04-05 05:37:04', '2026-04-05 05:37:04'),
(124, 64, 8, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367424630858\"\n}\n', NULL, '2026-04-05 00:37:04', '2026-04-05 05:37:04', '2026-04-05 05:37:04'),
(125, 64, 9, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367425144467\"\n}\n', NULL, '2026-04-05 00:37:05', '2026-04-05 05:37:04', '2026-04-05 05:37:05'),
(126, 64, 10, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367425528436\"\n}\n', NULL, '2026-04-05 00:37:05', '2026-04-05 05:37:05', '2026-04-05 05:37:05'),
(127, 64, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367425999981\"\n}\n', NULL, '2026-04-05 00:37:06', '2026-04-05 05:37:05', '2026-04-05 05:37:06'),
(128, 65, NULL, 'failed', 'fcm', NULL, 'Suppressed: user active in challenge chat', NULL, '2026-04-05 05:39:10', '2026-04-05 05:39:10'),
(129, 66, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775367681631048%6e6531436e653143\"\n}\n', NULL, '2026-04-05 00:41:21', '2026-04-05 05:41:21', '2026-04-05 05:41:21'),
(130, 66, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367681880424\"\n}\n', NULL, '2026-04-05 00:41:22', '2026-04-05 05:41:21', '2026-04-05 05:41:22'),
(131, 66, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367682173047\"\n}\n', NULL, '2026-04-05 00:41:22', '2026-04-05 05:41:22', '2026-04-05 05:41:22'),
(132, 66, 7, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367682483403\"\n}\n', NULL, '2026-04-05 00:41:22', '2026-04-05 05:41:22', '2026-04-05 05:41:22'),
(133, 66, 8, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367682829933\"\n}\n', NULL, '2026-04-05 00:41:23', '2026-04-05 05:41:22', '2026-04-05 05:41:23'),
(134, 66, 9, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367683290530\"\n}\n', NULL, '2026-04-05 00:41:23', '2026-04-05 05:41:23', '2026-04-05 05:41:23'),
(135, 66, 10, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367683683813\"\n}\n', NULL, '2026-04-05 00:41:23', '2026-04-05 05:41:23', '2026-04-05 05:41:23'),
(136, 66, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367684060969\"\n}\n', NULL, '2026-04-05 00:41:24', '2026-04-05 05:41:23', '2026-04-05 05:41:24'),
(137, 67, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775367697465215%6e6531436e653143\"\n}\n', NULL, '2026-04-05 00:41:37', '2026-04-05 05:41:37', '2026-04-05 05:41:37'),
(138, 67, 2, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367697694388\"\n}\n', NULL, '2026-04-05 00:41:37', '2026-04-05 05:41:37', '2026-04-05 05:41:37'),
(139, 67, 4, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367697947200\"\n}\n', NULL, '2026-04-05 00:41:38', '2026-04-05 05:41:37', '2026-04-05 05:41:38'),
(140, 67, 7, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367698281197\"\n}\n', NULL, '2026-04-05 00:41:38', '2026-04-05 05:41:38', '2026-04-05 05:41:38'),
(141, 67, 8, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367698589432\"\n}\n', NULL, '2026-04-05 00:41:38', '2026-04-05 05:41:38', '2026-04-05 05:41:38'),
(142, 67, 9, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367698961617\"\n}\n', NULL, '2026-04-05 00:41:39', '2026-04-05 05:41:38', '2026-04-05 05:41:39'),
(143, 67, 10, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367699436711\"\n}\n', NULL, '2026-04-05 00:41:39', '2026-04-05 05:41:39', '2026-04-05 05:41:39'),
(144, 67, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367699808494\"\n}\n', NULL, '2026-04-05 00:41:39', '2026-04-05 05:41:39', '2026-04-05 05:41:39'),
(145, 68, NULL, 'failed', 'fcm', NULL, 'Suppressed: user active in challenge chat', NULL, '2026-04-05 05:42:10', '2026-04-05 05:42:10'),
(146, 69, 3, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367735305946\"\n}\n', NULL, '2026-04-05 00:42:15', '2026-04-05 05:42:15', '2026-04-05 05:42:15'),
(147, 69, 5, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367735588892\"\n}\n', NULL, '2026-04-05 00:42:15', '2026-04-05 05:42:15', '2026-04-05 05:42:15'),
(148, 69, 6, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367736061513\"\n}\n', NULL, '2026-04-05 00:42:16', '2026-04-05 05:42:15', '2026-04-05 05:42:16'),
(149, 69, 11, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367736360558\"\n}\n', NULL, '2026-04-05 00:42:16', '2026-04-05 05:42:16', '2026-04-05 05:42:16'),
(150, 69, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775367736678137\"\n}\n', NULL, '2026-04-05 00:42:17', '2026-04-05 05:42:16', '2026-04-05 05:42:17'),
(151, 70, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775409818288762%6e6531436e653143\"\n}\n', NULL, '2026-04-05 12:23:38', '2026-04-05 17:23:37', '2026-04-05 17:23:38'),
(152, 70, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-05 12:23:38', '2026-04-05 17:23:38', '2026-04-05 17:23:38'),
(153, 70, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-05 12:23:39', '2026-04-05 17:23:38', '2026-04-05 17:23:39'),
(154, 70, 7, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775409819316884\"\n}\n', NULL, '2026-04-05 12:23:39', '2026-04-05 17:23:39', '2026-04-05 17:23:39'),
(155, 70, 8, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775409819652827\"\n}\n', NULL, '2026-04-05 12:23:39', '2026-04-05 17:23:39', '2026-04-05 17:23:39'),
(156, 70, 9, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775409820124959\"\n}\n', NULL, '2026-04-05 12:23:40', '2026-04-05 17:23:39', '2026-04-05 17:23:40'),
(157, 70, 10, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775409820347381\"\n}\n', NULL, '2026-04-05 12:23:40', '2026-04-05 17:23:40', '2026-04-05 17:23:40'),
(158, 70, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775409820781794\"\n}\n', NULL, '2026-04-05 12:23:41', '2026-04-05 17:23:40', '2026-04-05 17:23:41'),
(159, 71, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-05 12:23:41', '2026-04-05 17:23:41', '2026-04-05 17:23:41'),
(160, 71, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-05 12:23:41', '2026-04-05 17:23:41', '2026-04-05 17:23:41'),
(161, 71, 6, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775409821846790\"\n}\n', NULL, '2026-04-05 12:23:42', '2026-04-05 17:23:41', '2026-04-05 17:23:42'),
(162, 71, 11, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775409822166217\"\n}\n', NULL, '2026-04-05 12:23:42', '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(163, 71, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775409822493607\"\n}\n', NULL, '2026-04-05 12:23:42', '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(164, 72, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(165, 73, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(166, 74, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(167, 75, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(168, 76, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(169, 77, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(170, 78, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(171, 79, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(172, 80, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(173, 81, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(174, 82, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(175, 83, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(176, 84, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:42', '2026-04-05 17:23:42'),
(177, 85, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(178, 86, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(179, 87, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(180, 88, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(181, 89, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(182, 90, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(183, 91, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(184, 92, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(185, 93, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(186, 94, NULL, 'failed', 'fcm', NULL, 'No active devices', NULL, '2026-04-05 17:23:43', '2026-04-05 17:23:43'),
(187, 95, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775583947076243%6e6531436e653143\"\n}\n', NULL, '2026-04-07 12:45:47', '2026-04-07 17:45:46', '2026-04-07 17:45:47'),
(188, 95, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:47', '2026-04-07 17:45:47', '2026-04-07 17:45:47'),
(189, 95, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:47', '2026-04-07 17:45:47', '2026-04-07 17:45:47'),
(190, 95, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:47', '2026-04-07 17:45:47', '2026-04-07 17:45:47'),
(191, 95, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:48', '2026-04-07 17:45:47', '2026-04-07 17:45:48'),
(192, 95, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:48', '2026-04-07 17:45:48', '2026-04-07 17:45:48'),
(193, 95, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:49', '2026-04-07 17:45:48', '2026-04-07 17:45:49'),
(194, 95, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775583949369900\"\n}\n', NULL, '2026-04-07 12:45:49', '2026-04-07 17:45:49', '2026-04-07 17:45:49'),
(195, 95, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775583949686981\"\n}\n', NULL, '2026-04-07 12:45:50', '2026-04-07 17:45:49', '2026-04-07 17:45:50'),
(196, 95, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775583950254525\"\n}\n', NULL, '2026-04-07 12:45:50', '2026-04-07 17:45:50', '2026-04-07 17:45:50'),
(197, 96, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:50', '2026-04-07 17:45:50', '2026-04-07 17:45:50'),
(198, 96, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:50', '2026-04-07 17:45:50', '2026-04-07 17:45:50'),
(199, 96, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:51', '2026-04-07 17:45:50', '2026-04-07 17:45:51'),
(200, 96, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      },\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.ApnsError\",\n        \"statusCode\": 410,\n        \"reason\": \"Unregistered\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 12:45:51', '2026-04-07 17:45:51', '2026-04-07 17:45:51'),
(201, 96, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775583951876931\"\n}\n', NULL, '2026-04-07 12:45:52', '2026-04-07 17:45:51', '2026-04-07 17:45:52'),
(202, 97, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775587358521342%6e6531436e653143\"\n}\n', NULL, '2026-04-07 13:42:38', '2026-04-07 18:42:38', '2026-04-07 18:42:38'),
(203, 97, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:38', '2026-04-07 18:42:38', '2026-04-07 18:42:38'),
(204, 97, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:39', '2026-04-07 18:42:38', '2026-04-07 18:42:39'),
(205, 97, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:39', '2026-04-07 18:42:39', '2026-04-07 18:42:39'),
(206, 97, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:39', '2026-04-07 18:42:39', '2026-04-07 18:42:39'),
(207, 97, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:39', '2026-04-07 18:42:39', '2026-04-07 18:42:39'),
(208, 97, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:39', '2026-04-07 18:42:39', '2026-04-07 18:42:39'),
(209, 97, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775587360042006\"\n}\n', NULL, '2026-04-07 13:42:40', '2026-04-07 18:42:39', '2026-04-07 18:42:40'),
(210, 97, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775587360448143\"\n}\n', NULL, '2026-04-07 13:42:40', '2026-04-07 18:42:40', '2026-04-07 18:42:40'),
(211, 97, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775587360784288\"\n}\n', NULL, '2026-04-07 13:42:41', '2026-04-07 18:42:40', '2026-04-07 18:42:41'),
(212, 98, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:41', '2026-04-07 18:42:41', '2026-04-07 18:42:41'),
(213, 98, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:41', '2026-04-07 18:42:41', '2026-04-07 18:42:41'),
(214, 98, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:41', '2026-04-07 18:42:41', '2026-04-07 18:42:41'),
(215, 98, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:42:41', '2026-04-07 18:42:41', '2026-04-07 18:42:41'),
(216, 98, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775587362024324\"\n}\n', NULL, '2026-04-07 13:42:42', '2026-04-07 18:42:41', '2026-04-07 18:42:42'),
(217, 99, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775587444853820%6e6531436e653143\"\n}\n', NULL, '2026-04-07 13:44:04', '2026-04-07 18:44:04', '2026-04-07 18:44:04'),
(218, 99, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:05', '2026-04-07 18:44:04', '2026-04-07 18:44:05'),
(219, 99, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:05', '2026-04-07 18:44:05', '2026-04-07 18:44:05'),
(220, 99, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:05', '2026-04-07 18:44:05', '2026-04-07 18:44:05'),
(221, 99, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:05', '2026-04-07 18:44:05', '2026-04-07 18:44:05'),
(222, 99, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:05', '2026-04-07 18:44:05', '2026-04-07 18:44:05'),
(223, 99, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:05', '2026-04-07 18:44:05', '2026-04-07 18:44:05'),
(224, 99, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775587446030994\"\n}\n', NULL, '2026-04-07 13:44:06', '2026-04-07 18:44:05', '2026-04-07 18:44:06'),
(225, 99, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775587446473669\"\n}\n', NULL, '2026-04-07 13:44:06', '2026-04-07 18:44:06', '2026-04-07 18:44:06'),
(226, 99, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775587446953755\"\n}\n', NULL, '2026-04-07 13:44:07', '2026-04-07 18:44:06', '2026-04-07 18:44:07'),
(227, 100, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:07', '2026-04-07 18:44:07', '2026-04-07 18:44:07'),
(228, 100, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:07', '2026-04-07 18:44:07', '2026-04-07 18:44:07'),
(229, 100, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:07', '2026-04-07 18:44:07', '2026-04-07 18:44:07'),
(230, 100, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 13:44:07', '2026-04-07 18:44:07', '2026-04-07 18:44:07'),
(231, 100, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775587447861932\"\n}\n', NULL, '2026-04-07 13:44:07', '2026-04-07 18:44:07', '2026-04-07 18:44:07'),
(232, 101, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 15:06:20', '2026-04-07 20:06:20', '2026-04-07 20:06:20'),
(233, 101, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 15:06:20', '2026-04-07 20:06:20', '2026-04-07 20:06:20'),
(234, 101, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 15:06:20', '2026-04-07 20:06:20', '2026-04-07 20:06:20'),
(235, 101, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 15:06:21', '2026-04-07 20:06:20', '2026-04-07 20:06:21'),
(236, 101, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775592381301046\"\n}\n', NULL, '2026-04-07 15:06:21', '2026-04-07 20:06:21', '2026-04-07 20:06:21'),
(237, 101, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775592381693732\"\n}\n', NULL, '2026-04-07 15:06:21', '2026-04-07 20:06:21', '2026-04-07 20:06:21'),
(238, 102, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775612848372212%6e6531436e653143\"\n}\n', NULL, '2026-04-07 20:47:28', '2026-04-08 01:47:28', '2026-04-08 01:47:28'),
(239, 102, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:28', '2026-04-08 01:47:28', '2026-04-08 01:47:28'),
(240, 102, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:28', '2026-04-08 01:47:28', '2026-04-08 01:47:28'),
(241, 102, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:29', '2026-04-08 01:47:28', '2026-04-08 01:47:29'),
(242, 102, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:29', '2026-04-08 01:47:29', '2026-04-08 01:47:29');
INSERT INTO `push_dispatch_logs` (`id`, `push_notification_id`, `user_device_id`, `status`, `provider`, `provider_response`, `error_message`, `sent_at`, `created_at`, `updated_at`) VALUES
(243, 102, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:29', '2026-04-08 01:47:29', '2026-04-08 01:47:29'),
(244, 102, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:29', '2026-04-08 01:47:29', '2026-04-08 01:47:29'),
(245, 102, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775612849754321\"\n}\n', NULL, '2026-04-07 20:47:29', '2026-04-08 01:47:29', '2026-04-08 01:47:29'),
(246, 102, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775612850036070\"\n}\n', NULL, '2026-04-07 20:47:30', '2026-04-08 01:47:29', '2026-04-08 01:47:30'),
(247, 102, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775612850261972\"\n}\n', NULL, '2026-04-07 20:47:30', '2026-04-08 01:47:30', '2026-04-08 01:47:30'),
(248, 103, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:30', '2026-04-08 01:47:30', '2026-04-08 01:47:30'),
(249, 103, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:30', '2026-04-08 01:47:30', '2026-04-08 01:47:30'),
(250, 103, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:31', '2026-04-08 01:47:30', '2026-04-08 01:47:31'),
(251, 103, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-07 20:47:31', '2026-04-08 01:47:31', '2026-04-08 01:47:31'),
(252, 103, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775612851242607\"\n}\n', NULL, '2026-04-07 20:47:31', '2026-04-08 01:47:31', '2026-04-08 01:47:31'),
(253, 103, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775612851507590\"\n}\n', NULL, '2026-04-07 20:47:31', '2026-04-08 01:47:31', '2026-04-08 01:47:31'),
(254, 103, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775612851911388\"\n}\n', NULL, '2026-04-07 20:47:32', '2026-04-08 01:47:31', '2026-04-08 01:47:32'),
(255, 104, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775632589596275%6e6531436e653143\"\n}\n', NULL, '2026-04-08 02:16:29', '2026-04-08 07:16:29', '2026-04-08 07:16:29'),
(256, 104, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:29', '2026-04-08 07:16:29', '2026-04-08 07:16:29'),
(257, 104, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:29', '2026-04-08 07:16:29', '2026-04-08 07:16:29'),
(258, 104, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:30', '2026-04-08 07:16:29', '2026-04-08 07:16:30'),
(259, 104, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:30', '2026-04-08 07:16:30', '2026-04-08 07:16:30'),
(260, 104, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:30', '2026-04-08 07:16:30', '2026-04-08 07:16:30'),
(261, 104, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:30', '2026-04-08 07:16:30', '2026-04-08 07:16:30'),
(262, 104, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632590782115\"\n}\n', NULL, '2026-04-08 02:16:30', '2026-04-08 07:16:30', '2026-04-08 07:16:30'),
(263, 104, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632591183601\"\n}\n', NULL, '2026-04-08 02:16:31', '2026-04-08 07:16:30', '2026-04-08 07:16:31'),
(264, 104, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632591525958\"\n}\n', NULL, '2026-04-08 02:16:31', '2026-04-08 07:16:31', '2026-04-08 07:16:31'),
(265, 105, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:31', '2026-04-08 07:16:31', '2026-04-08 07:16:31'),
(266, 105, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:31', '2026-04-08 07:16:31', '2026-04-08 07:16:31'),
(267, 105, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:32', '2026-04-08 07:16:31', '2026-04-08 07:16:32'),
(268, 105, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:16:32', '2026-04-08 07:16:32', '2026-04-08 07:16:32'),
(269, 105, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632592428260\"\n}\n', NULL, '2026-04-08 02:16:32', '2026-04-08 07:16:32', '2026-04-08 07:16:32'),
(270, 105, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632592710779\"\n}\n', NULL, '2026-04-08 02:16:32', '2026-04-08 07:16:32', '2026-04-08 07:16:32'),
(271, 105, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632593011038\"\n}\n', NULL, '2026-04-08 02:16:33', '2026-04-08 07:16:32', '2026-04-08 07:16:33'),
(272, 105, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632593331739\"\n}\n', NULL, '2026-04-08 02:16:33', '2026-04-08 07:16:33', '2026-04-08 07:16:33'),
(273, 106, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775632676075579%6e6531436e653143\"\n}\n', NULL, '2026-04-08 02:17:56', '2026-04-08 07:17:55', '2026-04-08 07:17:56'),
(274, 106, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:56', '2026-04-08 07:17:56', '2026-04-08 07:17:56'),
(275, 106, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:56', '2026-04-08 07:17:56', '2026-04-08 07:17:56'),
(276, 106, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:56', '2026-04-08 07:17:56', '2026-04-08 07:17:56'),
(277, 106, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:57', '2026-04-08 07:17:56', '2026-04-08 07:17:57'),
(278, 106, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:57', '2026-04-08 07:17:57', '2026-04-08 07:17:57'),
(279, 106, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:57', '2026-04-08 07:17:57', '2026-04-08 07:17:57'),
(280, 106, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632677470938\"\n}\n', NULL, '2026-04-08 02:17:57', '2026-04-08 07:17:57', '2026-04-08 07:17:57'),
(281, 106, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632677760532\"\n}\n', NULL, '2026-04-08 02:17:57', '2026-04-08 07:17:57', '2026-04-08 07:17:57'),
(282, 106, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632678107390\"\n}\n', NULL, '2026-04-08 02:17:58', '2026-04-08 07:17:57', '2026-04-08 07:17:58'),
(283, 107, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:58', '2026-04-08 07:17:58', '2026-04-08 07:17:58'),
(284, 107, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:58', '2026-04-08 07:17:58', '2026-04-08 07:17:58'),
(285, 107, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:59', '2026-04-08 07:17:58', '2026-04-08 07:17:59'),
(286, 107, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 02:17:59', '2026-04-08 07:17:59', '2026-04-08 07:17:59'),
(287, 107, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632679391805\"\n}\n', NULL, '2026-04-08 02:17:59', '2026-04-08 07:17:59', '2026-04-08 07:17:59'),
(288, 107, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632679750124\"\n}\n', NULL, '2026-04-08 02:17:59', '2026-04-08 07:17:59', '2026-04-08 07:17:59'),
(289, 107, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632680017786\"\n}\n', NULL, '2026-04-08 02:18:00', '2026-04-08 07:17:59', '2026-04-08 07:18:00'),
(290, 107, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775632680500342\"\n}\n', NULL, '2026-04-08 02:18:00', '2026-04-08 07:18:00', '2026-04-08 07:18:00'),
(291, 108, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775665473984012%6e6531436e653143\"\n}\n', NULL, '2026-04-08 11:24:34', '2026-04-08 16:24:33', '2026-04-08 16:24:34'),
(292, 108, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:34', '2026-04-08 16:24:34', '2026-04-08 16:24:34'),
(293, 108, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:34', '2026-04-08 16:24:34', '2026-04-08 16:24:34'),
(294, 108, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:34', '2026-04-08 16:24:34', '2026-04-08 16:24:34'),
(295, 108, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:34', '2026-04-08 16:24:34', '2026-04-08 16:24:34'),
(296, 108, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:35', '2026-04-08 16:24:34', '2026-04-08 16:24:35'),
(297, 108, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:35', '2026-04-08 16:24:35', '2026-04-08 16:24:35'),
(298, 108, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775665475598647\"\n}\n', NULL, '2026-04-08 11:24:35', '2026-04-08 16:24:35', '2026-04-08 16:24:35'),
(299, 108, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775665476036600\"\n}\n', NULL, '2026-04-08 11:24:36', '2026-04-08 16:24:35', '2026-04-08 16:24:36'),
(300, 108, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775665476343089\"\n}\n', NULL, '2026-04-08 11:24:36', '2026-04-08 16:24:36', '2026-04-08 16:24:36'),
(301, 109, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:36', '2026-04-08 16:24:36', '2026-04-08 16:24:36'),
(302, 109, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:36', '2026-04-08 16:24:36', '2026-04-08 16:24:36'),
(303, 109, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:37', '2026-04-08 16:24:36', '2026-04-08 16:24:37'),
(304, 109, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 11:24:37', '2026-04-08 16:24:37', '2026-04-08 16:24:37'),
(305, 109, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775665477647690\"\n}\n', NULL, '2026-04-08 11:24:37', '2026-04-08 16:24:37', '2026-04-08 16:24:37'),
(306, 109, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775665477986715\"\n}\n', NULL, '2026-04-08 11:24:38', '2026-04-08 16:24:37', '2026-04-08 16:24:38'),
(307, 109, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775665478453583\"\n}\n', NULL, '2026-04-08 11:24:38', '2026-04-08 16:24:38', '2026-04-08 16:24:38'),
(308, 109, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775665478761214\"\n}\n', NULL, '2026-04-08 11:24:39', '2026-04-08 16:24:38', '2026-04-08 16:24:39'),
(309, 110, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775676689758044%6e6531436e653143\"\n}\n', NULL, '2026-04-08 14:31:29', '2026-04-08 19:31:29', '2026-04-08 19:31:29'),
(310, 110, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:30', '2026-04-08 19:31:29', '2026-04-08 19:31:30'),
(311, 110, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:30', '2026-04-08 19:31:30', '2026-04-08 19:31:30'),
(312, 110, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:30', '2026-04-08 19:31:30', '2026-04-08 19:31:30'),
(313, 110, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:30', '2026-04-08 19:31:30', '2026-04-08 19:31:30'),
(314, 110, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:30', '2026-04-08 19:31:30', '2026-04-08 19:31:30'),
(315, 110, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:31', '2026-04-08 19:31:30', '2026-04-08 19:31:31'),
(316, 110, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775676691116735\"\n}\n', NULL, '2026-04-08 14:31:31', '2026-04-08 19:31:31', '2026-04-08 19:31:31'),
(317, 110, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775676691591258\"\n}\n', NULL, '2026-04-08 14:31:31', '2026-04-08 19:31:31', '2026-04-08 19:31:31'),
(318, 110, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775676692095832\"\n}\n', NULL, '2026-04-08 14:31:32', '2026-04-08 19:31:31', '2026-04-08 19:31:32'),
(319, 110, 19, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775676692536034\"\n}\n', NULL, '2026-04-08 14:31:32', '2026-04-08 19:31:32', '2026-04-08 19:31:32'),
(320, 111, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:32', '2026-04-08 19:31:32', '2026-04-08 19:31:32'),
(321, 111, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:33', '2026-04-08 19:31:32', '2026-04-08 19:31:33'),
(322, 111, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:33', '2026-04-08 19:31:33', '2026-04-08 19:31:33'),
(323, 111, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 14:31:33', '2026-04-08 19:31:33', '2026-04-08 19:31:33'),
(324, 111, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775676693659410\"\n}\n', NULL, '2026-04-08 14:31:33', '2026-04-08 19:31:33', '2026-04-08 19:31:33'),
(325, 111, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775676693966088\"\n}\n', NULL, '2026-04-08 14:31:34', '2026-04-08 19:31:33', '2026-04-08 19:31:34'),
(326, 111, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775676694322157\"\n}\n', NULL, '2026-04-08 14:31:34', '2026-04-08 19:31:34', '2026-04-08 19:31:34'),
(327, 111, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775676694773427\"\n}\n', NULL, '2026-04-08 14:31:35', '2026-04-08 19:31:34', '2026-04-08 19:31:35'),
(328, 111, 20, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775676695188450\"\n}\n', NULL, '2026-04-08 14:31:35', '2026-04-08 19:31:35', '2026-04-08 19:31:35'),
(329, 112, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775682767681217%6e6531436e653143\"\n}\n', NULL, '2026-04-08 16:12:47', '2026-04-08 21:12:47', '2026-04-08 21:12:47'),
(330, 112, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:47', '2026-04-08 21:12:47', '2026-04-08 21:12:47'),
(331, 112, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:48', '2026-04-08 21:12:47', '2026-04-08 21:12:48'),
(332, 112, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:48', '2026-04-08 21:12:48', '2026-04-08 21:12:48'),
(333, 112, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:48', '2026-04-08 21:12:48', '2026-04-08 21:12:48'),
(334, 112, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:48', '2026-04-08 21:12:48', '2026-04-08 21:12:48'),
(335, 112, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:48', '2026-04-08 21:12:48', '2026-04-08 21:12:48'),
(336, 112, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682768946515\"\n}\n', NULL, '2026-04-08 16:12:49', '2026-04-08 21:12:48', '2026-04-08 21:12:49'),
(337, 112, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682769238242\"\n}\n', NULL, '2026-04-08 16:12:49', '2026-04-08 21:12:49', '2026-04-08 21:12:49'),
(338, 112, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682769608800\"\n}\n', NULL, '2026-04-08 16:12:49', '2026-04-08 21:12:49', '2026-04-08 21:12:49'),
(339, 112, 19, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682770082387\"\n}\n', NULL, '2026-04-08 16:12:50', '2026-04-08 21:12:49', '2026-04-08 21:12:50'),
(340, 112, 21, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682770498725\"\n}\n', NULL, '2026-04-08 16:12:50', '2026-04-08 21:12:50', '2026-04-08 21:12:50'),
(341, 113, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:50', '2026-04-08 21:12:50', '2026-04-08 21:12:50'),
(342, 113, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:51', '2026-04-08 21:12:50', '2026-04-08 21:12:51'),
(343, 113, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:51', '2026-04-08 21:12:51', '2026-04-08 21:12:51'),
(344, 113, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 16:12:51', '2026-04-08 21:12:51', '2026-04-08 21:12:51'),
(345, 113, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682771662270\"\n}\n', NULL, '2026-04-08 16:12:51', '2026-04-08 21:12:51', '2026-04-08 21:12:51'),
(346, 113, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682772099020\"\n}\n', NULL, '2026-04-08 16:12:52', '2026-04-08 21:12:51', '2026-04-08 21:12:52'),
(347, 113, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682772490408\"\n}\n', NULL, '2026-04-08 16:12:52', '2026-04-08 21:12:52', '2026-04-08 21:12:52'),
(348, 113, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682772882109\"\n}\n', NULL, '2026-04-08 16:12:53', '2026-04-08 21:12:52', '2026-04-08 21:12:53'),
(349, 113, 20, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682773218931\"\n}\n', NULL, '2026-04-08 16:12:53', '2026-04-08 21:12:53', '2026-04-08 21:12:53'),
(350, 113, 22, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775682773463989\"\n}\n', NULL, '2026-04-08 16:12:53', '2026-04-08 21:12:53', '2026-04-08 21:12:53'),
(351, 114, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775692598151172%6e6531436e653143\"\n}\n', NULL, '2026-04-08 18:56:38', '2026-04-08 23:56:37', '2026-04-08 23:56:38'),
(352, 114, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:38', '2026-04-08 23:56:38', '2026-04-08 23:56:38'),
(353, 114, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:38', '2026-04-08 23:56:38', '2026-04-08 23:56:38'),
(354, 114, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:38', '2026-04-08 23:56:38', '2026-04-08 23:56:38'),
(355, 114, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:39', '2026-04-08 23:56:38', '2026-04-08 23:56:39'),
(356, 114, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:39', '2026-04-08 23:56:39', '2026-04-08 23:56:39'),
(357, 114, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:39', '2026-04-08 23:56:39', '2026-04-08 23:56:39'),
(358, 114, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692599598009\"\n}\n', NULL, '2026-04-08 18:56:39', '2026-04-08 23:56:39', '2026-04-08 23:56:39'),
(359, 114, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692599855304\"\n}\n', NULL, '2026-04-08 18:56:40', '2026-04-08 23:56:39', '2026-04-08 23:56:40'),
(360, 114, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692600423590\"\n}\n', NULL, '2026-04-08 18:56:40', '2026-04-08 23:56:40', '2026-04-08 23:56:40'),
(361, 114, 19, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692600718635\"\n}\n', NULL, '2026-04-08 18:56:40', '2026-04-08 23:56:40', '2026-04-08 23:56:40'),
(362, 114, 21, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692601078689\"\n}\n', NULL, '2026-04-08 18:56:41', '2026-04-08 23:56:40', '2026-04-08 23:56:41'),
(363, 114, 23, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692601394594\"\n}\n', NULL, '2026-04-08 18:56:41', '2026-04-08 23:56:41', '2026-04-08 23:56:41'),
(364, 114, 24, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692601716809\"\n}\n', NULL, '2026-04-08 18:56:41', '2026-04-08 23:56:41', '2026-04-08 23:56:41'),
(365, 115, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:42', '2026-04-08 23:56:41', '2026-04-08 23:56:42'),
(366, 115, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:42', '2026-04-08 23:56:42', '2026-04-08 23:56:42'),
(367, 115, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:42', '2026-04-08 23:56:42', '2026-04-08 23:56:42'),
(368, 115, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 18:56:42', '2026-04-08 23:56:42', '2026-04-08 23:56:42'),
(369, 115, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692602827692\"\n}\n', NULL, '2026-04-08 18:56:43', '2026-04-08 23:56:42', '2026-04-08 23:56:43'),
(370, 115, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692603198314\"\n}\n', NULL, '2026-04-08 18:56:43', '2026-04-08 23:56:43', '2026-04-08 23:56:43'),
(371, 115, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692603541983\"\n}\n', NULL, '2026-04-08 18:56:43', '2026-04-08 23:56:43', '2026-04-08 23:56:43'),
(372, 115, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692603799888\"\n}\n', NULL, '2026-04-08 18:56:44', '2026-04-08 23:56:43', '2026-04-08 23:56:44'),
(373, 115, 20, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692604161121\"\n}\n', NULL, '2026-04-08 18:56:44', '2026-04-08 23:56:44', '2026-04-08 23:56:44'),
(374, 115, 22, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775692604514021\"\n}\n', NULL, '2026-04-08 18:56:44', '2026-04-08 23:56:44', '2026-04-08 23:56:44'),
(375, 116, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775702382216020%6e6531436e653143\"\n}\n', NULL, '2026-04-08 21:39:42', '2026-04-09 02:39:41', '2026-04-09 02:39:42'),
(376, 116, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:42', '2026-04-09 02:39:42', '2026-04-09 02:39:42'),
(377, 116, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:42', '2026-04-09 02:39:42', '2026-04-09 02:39:42'),
(378, 116, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:42', '2026-04-09 02:39:42', '2026-04-09 02:39:42'),
(379, 116, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:43', '2026-04-09 02:39:42', '2026-04-09 02:39:43'),
(380, 116, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:43', '2026-04-09 02:39:43', '2026-04-09 02:39:43'),
(381, 116, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:43', '2026-04-09 02:39:43', '2026-04-09 02:39:43'),
(382, 116, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702383804872\"\n}\n', NULL, '2026-04-08 21:39:43', '2026-04-09 02:39:43', '2026-04-09 02:39:43'),
(383, 116, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702384113281\"\n}\n', NULL, '2026-04-08 21:39:44', '2026-04-09 02:39:43', '2026-04-09 02:39:44'),
(384, 116, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702384491324\"\n}\n', NULL, '2026-04-08 21:39:44', '2026-04-09 02:39:44', '2026-04-09 02:39:44'),
(385, 116, 19, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702384920812\"\n}\n', NULL, '2026-04-08 21:39:45', '2026-04-09 02:39:44', '2026-04-09 02:39:45'),
(386, 116, 21, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702385312855\"\n}\n', NULL, '2026-04-08 21:39:45', '2026-04-09 02:39:45', '2026-04-09 02:39:45'),
(387, 116, 23, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702385743053\"\n}\n', NULL, '2026-04-08 21:39:45', '2026-04-09 02:39:45', '2026-04-09 02:39:45'),
(388, 116, 24, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702386041142\"\n}\n', NULL, '2026-04-08 21:39:46', '2026-04-09 02:39:45', '2026-04-09 02:39:46'),
(389, 116, 25, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702386455042\"\n}\n', NULL, '2026-04-08 21:39:46', '2026-04-09 02:39:46', '2026-04-09 02:39:46'),
(390, 116, 26, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702386811405\"\n}\n', NULL, '2026-04-08 21:39:47', '2026-04-09 02:39:46', '2026-04-09 02:39:47'),
(391, 117, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:47', '2026-04-09 02:39:47', '2026-04-09 02:39:47'),
(392, 117, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:47', '2026-04-09 02:39:47', '2026-04-09 02:39:47'),
(393, 117, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:47', '2026-04-09 02:39:47', '2026-04-09 02:39:47'),
(394, 117, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:39:48', '2026-04-09 02:39:47', '2026-04-09 02:39:48'),
(395, 117, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702388169455\"\n}\n', NULL, '2026-04-08 21:39:48', '2026-04-09 02:39:48', '2026-04-09 02:39:48'),
(396, 117, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702388692690\"\n}\n', NULL, '2026-04-08 21:39:48', '2026-04-09 02:39:48', '2026-04-09 02:39:48'),
(397, 117, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702389054152\"\n}\n', NULL, '2026-04-08 21:39:49', '2026-04-09 02:39:48', '2026-04-09 02:39:49'),
(398, 117, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702389398704\"\n}\n', NULL, '2026-04-08 21:39:49', '2026-04-09 02:39:49', '2026-04-09 02:39:49'),
(399, 117, 20, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702389827550\"\n}\n', NULL, '2026-04-08 21:39:49', '2026-04-09 02:39:49', '2026-04-09 02:39:49'),
(400, 117, 22, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702390132118\"\n}\n', NULL, '2026-04-08 21:39:50', '2026-04-09 02:39:50', '2026-04-09 02:39:50'),
(401, 118, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775702757234463%6e6531436e653143\"\n}\n', NULL, '2026-04-08 21:45:57', '2026-04-09 02:45:57', '2026-04-09 02:45:57'),
(402, 118, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:45:57', '2026-04-09 02:45:57', '2026-04-09 02:45:57'),
(403, 118, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:45:57', '2026-04-09 02:45:57', '2026-04-09 02:45:57'),
(404, 118, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:45:57', '2026-04-09 02:45:57', '2026-04-09 02:45:57'),
(405, 118, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:45:58', '2026-04-09 02:45:57', '2026-04-09 02:45:58'),
(406, 118, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:45:58', '2026-04-09 02:45:58', '2026-04-09 02:45:58'),
(407, 118, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:45:58', '2026-04-09 02:45:58', '2026-04-09 02:45:58'),
(408, 118, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702758643153\"\n}\n', NULL, '2026-04-08 21:45:58', '2026-04-09 02:45:58', '2026-04-09 02:45:58'),
(409, 118, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702759073600\"\n}\n', NULL, '2026-04-08 21:45:59', '2026-04-09 02:45:58', '2026-04-09 02:45:59'),
(410, 118, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702759517431\"\n}\n', NULL, '2026-04-08 21:45:59', '2026-04-09 02:45:59', '2026-04-09 02:45:59');
INSERT INTO `push_dispatch_logs` (`id`, `push_notification_id`, `user_device_id`, `status`, `provider`, `provider_response`, `error_message`, `sent_at`, `created_at`, `updated_at`) VALUES
(411, 118, 19, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702759951641\"\n}\n', NULL, '2026-04-08 21:46:00', '2026-04-09 02:45:59', '2026-04-09 02:46:00'),
(412, 118, 21, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702760353070\"\n}\n', NULL, '2026-04-08 21:46:00', '2026-04-09 02:46:00', '2026-04-09 02:46:00'),
(413, 118, 23, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702760708849\"\n}\n', NULL, '2026-04-08 21:46:00', '2026-04-09 02:46:00', '2026-04-09 02:46:00'),
(414, 118, 24, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702761128524\"\n}\n', NULL, '2026-04-08 21:46:01', '2026-04-09 02:46:00', '2026-04-09 02:46:01'),
(415, 118, 25, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702761425106\"\n}\n', NULL, '2026-04-08 21:46:01', '2026-04-09 02:46:01', '2026-04-09 02:46:01'),
(416, 118, 26, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702761716418\"\n}\n', NULL, '2026-04-08 21:46:02', '2026-04-09 02:46:01', '2026-04-09 02:46:02'),
(417, 119, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:46:02', '2026-04-09 02:46:02', '2026-04-09 02:46:02'),
(418, 119, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:46:02', '2026-04-09 02:46:02', '2026-04-09 02:46:02'),
(419, 119, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:46:02', '2026-04-09 02:46:02', '2026-04-09 02:46:02'),
(420, 119, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 21:46:02', '2026-04-09 02:46:02', '2026-04-09 02:46:02'),
(421, 119, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702762943749\"\n}\n', NULL, '2026-04-08 21:46:03', '2026-04-09 02:46:02', '2026-04-09 02:46:03'),
(422, 119, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702763203411\"\n}\n', NULL, '2026-04-08 21:46:03', '2026-04-09 02:46:03', '2026-04-09 02:46:03'),
(423, 119, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702763605690\"\n}\n', NULL, '2026-04-08 21:46:03', '2026-04-09 02:46:03', '2026-04-09 02:46:03'),
(424, 119, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702763908041\"\n}\n', NULL, '2026-04-08 21:46:04', '2026-04-09 02:46:03', '2026-04-09 02:46:04'),
(425, 119, 20, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702764237953\"\n}\n', NULL, '2026-04-08 21:46:04', '2026-04-09 02:46:04', '2026-04-09 02:46:04'),
(426, 119, 22, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775702764541772\"\n}\n', NULL, '2026-04-08 21:46:04', '2026-04-09 02:46:04', '2026-04-09 02:46:04'),
(427, 120, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775705799288515%6e6531436e653143\"\n}\n', NULL, '2026-04-08 22:36:39', '2026-04-09 03:36:38', '2026-04-09 03:36:39'),
(428, 120, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:39', '2026-04-09 03:36:39', '2026-04-09 03:36:39'),
(429, 120, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:39', '2026-04-09 03:36:39', '2026-04-09 03:36:39'),
(430, 120, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:39', '2026-04-09 03:36:39', '2026-04-09 03:36:39'),
(431, 120, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:40', '2026-04-09 03:36:39', '2026-04-09 03:36:40'),
(432, 120, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:40', '2026-04-09 03:36:40', '2026-04-09 03:36:40'),
(433, 120, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:40', '2026-04-09 03:36:40', '2026-04-09 03:36:40'),
(434, 120, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705800882953\"\n}\n', NULL, '2026-04-08 22:36:41', '2026-04-09 03:36:40', '2026-04-09 03:36:41'),
(435, 120, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705801243786\"\n}\n', NULL, '2026-04-08 22:36:41', '2026-04-09 03:36:41', '2026-04-09 03:36:41'),
(436, 120, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705801889651\"\n}\n', NULL, '2026-04-08 22:36:42', '2026-04-09 03:36:41', '2026-04-09 03:36:42'),
(437, 120, 19, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705802262934\"\n}\n', NULL, '2026-04-08 22:36:42', '2026-04-09 03:36:42', '2026-04-09 03:36:42'),
(438, 120, 21, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705802603233\"\n}\n', NULL, '2026-04-08 22:36:42', '2026-04-09 03:36:42', '2026-04-09 03:36:42'),
(439, 120, 23, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705803114173\"\n}\n', NULL, '2026-04-08 22:36:43', '2026-04-09 03:36:42', '2026-04-09 03:36:43'),
(440, 120, 24, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705803560095\"\n}\n', NULL, '2026-04-08 22:36:43', '2026-04-09 03:36:43', '2026-04-09 03:36:43'),
(441, 120, 25, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705804082140\"\n}\n', NULL, '2026-04-08 22:36:44', '2026-04-09 03:36:43', '2026-04-09 03:36:44'),
(442, 120, 26, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705804416203\"\n}\n', NULL, '2026-04-08 22:36:44', '2026-04-09 03:36:44', '2026-04-09 03:36:44'),
(443, 120, 27, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705804734893\"\n}\n', NULL, '2026-04-08 22:36:45', '2026-04-09 03:36:44', '2026-04-09 03:36:45'),
(444, 121, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:45', '2026-04-09 03:36:45', '2026-04-09 03:36:45'),
(445, 121, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:45', '2026-04-09 03:36:45', '2026-04-09 03:36:45'),
(446, 121, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:45', '2026-04-09 03:36:45', '2026-04-09 03:36:45'),
(447, 121, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:36:45', '2026-04-09 03:36:45', '2026-04-09 03:36:45'),
(448, 121, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705806182662\"\n}\n', NULL, '2026-04-08 22:36:46', '2026-04-09 03:36:45', '2026-04-09 03:36:46'),
(449, 121, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705806492173\"\n}\n', NULL, '2026-04-08 22:36:46', '2026-04-09 03:36:46', '2026-04-09 03:36:46'),
(450, 121, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705806821825\"\n}\n', NULL, '2026-04-08 22:36:46', '2026-04-09 03:36:46', '2026-04-09 03:36:46'),
(451, 121, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705807138615\"\n}\n', NULL, '2026-04-08 22:36:47', '2026-04-09 03:36:46', '2026-04-09 03:36:47'),
(452, 121, 20, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705807445892\"\n}\n', NULL, '2026-04-08 22:36:47', '2026-04-09 03:36:47', '2026-04-09 03:36:47'),
(453, 121, 22, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775705807823461\"\n}\n', NULL, '2026-04-08 22:36:47', '2026-04-09 03:36:47', '2026-04-09 03:36:47'),
(454, 122, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775707055766793%6e6531436e653143\"\n}\n', NULL, '2026-04-08 22:57:35', '2026-04-09 03:57:35', '2026-04-09 03:57:35'),
(455, 122, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:35', '2026-04-09 03:57:35', '2026-04-09 03:57:35'),
(456, 122, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:36', '2026-04-09 03:57:35', '2026-04-09 03:57:36'),
(457, 122, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:36', '2026-04-09 03:57:36', '2026-04-09 03:57:36'),
(458, 122, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:36', '2026-04-09 03:57:36', '2026-04-09 03:57:36'),
(459, 122, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:36', '2026-04-09 03:57:36', '2026-04-09 03:57:36'),
(460, 122, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:37', '2026-04-09 03:57:36', '2026-04-09 03:57:37'),
(461, 122, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707057162125\"\n}\n', NULL, '2026-04-08 22:57:37', '2026-04-09 03:57:37', '2026-04-09 03:57:37'),
(462, 122, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707057436104\"\n}\n', NULL, '2026-04-08 22:57:37', '2026-04-09 03:57:37', '2026-04-09 03:57:37'),
(463, 122, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707057806416\"\n}\n', NULL, '2026-04-08 22:57:38', '2026-04-09 03:57:37', '2026-04-09 03:57:38'),
(464, 122, 19, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707058200340\"\n}\n', NULL, '2026-04-08 22:57:38', '2026-04-09 03:57:38', '2026-04-09 03:57:38'),
(465, 122, 21, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707058551939\"\n}\n', NULL, '2026-04-08 22:57:38', '2026-04-09 03:57:38', '2026-04-09 03:57:38'),
(466, 122, 23, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707058955060\"\n}\n', NULL, '2026-04-08 22:57:39', '2026-04-09 03:57:38', '2026-04-09 03:57:39'),
(467, 122, 24, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707059310934\"\n}\n', NULL, '2026-04-08 22:57:39', '2026-04-09 03:57:39', '2026-04-09 03:57:39'),
(468, 122, 25, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707059754799\"\n}\n', NULL, '2026-04-08 22:57:39', '2026-04-09 03:57:39', '2026-04-09 03:57:39'),
(469, 122, 26, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707060066700\"\n}\n', NULL, '2026-04-08 22:57:40', '2026-04-09 03:57:39', '2026-04-09 03:57:40'),
(470, 122, 27, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707060315208\"\n}\n', NULL, '2026-04-08 22:57:40', '2026-04-09 03:57:40', '2026-04-09 03:57:40'),
(471, 123, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:40', '2026-04-09 03:57:40', '2026-04-09 03:57:40'),
(472, 123, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:41', '2026-04-09 03:57:40', '2026-04-09 03:57:41'),
(473, 123, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:41', '2026-04-09 03:57:41', '2026-04-09 03:57:41'),
(474, 123, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:57:41', '2026-04-09 03:57:41', '2026-04-09 03:57:41'),
(475, 123, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707061702187\"\n}\n', NULL, '2026-04-08 22:57:41', '2026-04-09 03:57:41', '2026-04-09 03:57:41'),
(476, 123, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707061912190\"\n}\n', NULL, '2026-04-08 22:57:42', '2026-04-09 03:57:41', '2026-04-09 03:57:42'),
(477, 123, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707062232630\"\n}\n', NULL, '2026-04-08 22:57:42', '2026-04-09 03:57:42', '2026-04-09 03:57:42'),
(478, 123, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707062525430\"\n}\n', NULL, '2026-04-08 22:57:42', '2026-04-09 03:57:42', '2026-04-09 03:57:42'),
(479, 123, 20, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707062885751\"\n}\n', NULL, '2026-04-08 22:57:43', '2026-04-09 03:57:42', '2026-04-09 03:57:43'),
(480, 123, 22, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707063217422\"\n}\n', NULL, '2026-04-08 22:57:43', '2026-04-09 03:57:43', '2026-04-09 03:57:43'),
(481, 124, 1, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/0:1775707144001397%6e6531436e653143\"\n}\n', NULL, '2026-04-08 22:59:04', '2026-04-09 03:59:03', '2026-04-09 03:59:04'),
(482, 124, 2, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:04', '2026-04-09 03:59:04', '2026-04-09 03:59:04'),
(483, 124, 4, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:04', '2026-04-09 03:59:04', '2026-04-09 03:59:04'),
(484, 124, 7, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:04', '2026-04-09 03:59:04', '2026-04-09 03:59:04'),
(485, 124, 8, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:04', '2026-04-09 03:59:04', '2026-04-09 03:59:04'),
(486, 124, 9, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:05', '2026-04-09 03:59:04', '2026-04-09 03:59:05'),
(487, 124, 10, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:05', '2026-04-09 03:59:05', '2026-04-09 03:59:05'),
(488, 124, 12, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707145499410\"\n}\n', NULL, '2026-04-08 22:59:05', '2026-04-09 03:59:05', '2026-04-09 03:59:05'),
(489, 124, 14, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707146022253\"\n}\n', NULL, '2026-04-08 22:59:06', '2026-04-09 03:59:05', '2026-04-09 03:59:06'),
(490, 124, 15, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707146378800\"\n}\n', NULL, '2026-04-08 22:59:06', '2026-04-09 03:59:06', '2026-04-09 03:59:06'),
(491, 124, 19, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707146712095\"\n}\n', NULL, '2026-04-08 22:59:06', '2026-04-09 03:59:06', '2026-04-09 03:59:06'),
(492, 124, 21, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707146961672\"\n}\n', NULL, '2026-04-08 22:59:07', '2026-04-09 03:59:06', '2026-04-09 03:59:07'),
(493, 124, 23, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707147500144\"\n}\n', NULL, '2026-04-08 22:59:07', '2026-04-09 03:59:07', '2026-04-09 03:59:07'),
(494, 124, 24, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707147919788\"\n}\n', NULL, '2026-04-08 22:59:08', '2026-04-09 03:59:07', '2026-04-09 03:59:08'),
(495, 124, 25, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707148251403\"\n}\n', NULL, '2026-04-08 22:59:08', '2026-04-09 03:59:08', '2026-04-09 03:59:08'),
(496, 124, 26, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707148507052\"\n}\n', NULL, '2026-04-08 22:59:08', '2026-04-09 03:59:08', '2026-04-09 03:59:08'),
(497, 124, 27, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707148796643\"\n}\n', NULL, '2026-04-08 22:59:08', '2026-04-09 03:59:08', '2026-04-09 03:59:08'),
(498, 125, 3, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:09', '2026-04-09 03:59:08', '2026-04-09 03:59:09'),
(499, 125, 5, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:09', '2026-04-09 03:59:09', '2026-04-09 03:59:09'),
(500, 125, 6, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:09', '2026-04-09 03:59:09', '2026-04-09 03:59:09'),
(501, 125, 11, 'failed', 'fcm_v1', '{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Requested entity was not found.\",\n    \"status\": \"NOT_FOUND\",\n    \"details\": [\n      {\n        \"@type\": \"type.googleapis.com/google.firebase.fcm.v1.FcmError\",\n        \"errorCode\": \"UNREGISTERED\"\n      }\n    ]\n  }\n}\n', 'FCM HTTP 404', '2026-04-08 22:59:09', '2026-04-09 03:59:09', '2026-04-09 03:59:09'),
(502, 125, 13, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707149807419\"\n}\n', NULL, '2026-04-08 22:59:09', '2026-04-09 03:59:09', '2026-04-09 03:59:09'),
(503, 125, 16, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707150111274\"\n}\n', NULL, '2026-04-08 22:59:10', '2026-04-09 03:59:09', '2026-04-09 03:59:10'),
(504, 125, 17, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707150438351\"\n}\n', NULL, '2026-04-08 22:59:10', '2026-04-09 03:59:10', '2026-04-09 03:59:10'),
(505, 125, 18, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707150941087\"\n}\n', NULL, '2026-04-08 22:59:11', '2026-04-09 03:59:10', '2026-04-09 03:59:11'),
(506, 125, 20, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707151168465\"\n}\n', NULL, '2026-04-08 22:59:11', '2026-04-09 03:59:11', '2026-04-09 03:59:11'),
(507, 125, 22, 'sent', 'fcm_v1', '{\n  \"name\": \"projects/fulbii/messages/1775707151489232\"\n}\n', NULL, '2026-04-08 22:59:11', '2026-04-09 03:59:11', '2026-04-09 03:59:11');

-- --------------------------------------------------------

--
-- Table structure for table `push_notifications`
--

CREATE TABLE `push_notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `club_id` bigint(20) UNSIGNED DEFAULT NULL,
  `group_pichanga_id` bigint(20) UNSIGNED DEFAULT NULL,
  `type` varchar(80) NOT NULL,
  `title` varchar(140) NOT NULL,
  `body` varchar(500) NOT NULL,
  `data_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`data_json`)),
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `read_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `push_notifications`
--

INSERT INTO `push_notifications` (`id`, `user_id`, `club_id`, `group_pichanga_id`, `type`, `title`, `body`, `data_json`, `is_read`, `read_at`, `created_at`, `updated_at`) VALUES
(1, 1, 4, 1, 'pichanga_created', 'Nueva pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 1, '2026-03-29 03:37:01', '2026-03-29 08:36:09', '2026-03-29 08:37:01'),
(2, 38, 4, 1, 'pichanga_created', 'Nueva pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 1, '2026-03-29 03:36:24', '2026-03-29 08:36:09', '2026-03-29 08:36:24'),
(3, 1, 4, 2, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":2,\"club_id\":4}', 1, '2026-03-29 05:13:08', '2026-03-29 10:12:29', '2026-03-29 10:13:08'),
(4, 38, 4, 2, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":2,\"club_id\":4}', 1, '2026-03-29 05:14:49', '2026-03-29 10:12:29', '2026-03-29 10:14:49'),
(5, 1, 4, 3, 'pichanga_created', 'Nueva pichanga', 'partido', '{\"pichanga_id\":3,\"club_id\":4}', 1, '2026-03-29 09:47:55', '2026-03-29 14:47:11', '2026-03-29 14:47:55'),
(6, 38, 4, 3, 'pichanga_created', 'Nueva pichanga', 'partido', '{\"pichanga_id\":3,\"club_id\":4}', 1, '2026-03-29 15:03:59', '2026-03-29 14:47:11', '2026-03-29 20:03:59'),
(7, 1, 4, 4, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":4,\"club_id\":4}', 1, '2026-03-29 12:12:48', '2026-03-29 17:10:54', '2026-03-29 17:12:48'),
(8, 38, 4, 4, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":4,\"club_id\":4}', 1, '2026-03-29 15:04:01', '2026-03-29 17:10:54', '2026-03-29 20:04:01'),
(9, 1, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 1, '2026-03-30 02:48:11', '2026-03-30 07:46:02', '2026-03-30 07:48:11'),
(10, 38, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 1, '2026-04-02 01:15:01', '2026-03-30 07:46:02', '2026-04-02 06:15:01'),
(11, 3, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(12, 4, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(13, 5, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(14, 6, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(15, 7, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(16, 9, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(17, 10, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(18, 11, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(19, 12, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(20, 13, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(21, 14, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(22, 15, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(23, 16, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(24, 17, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(25, 18, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(26, 19, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(27, 20, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(28, 22, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(29, 23, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(30, 24, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(31, 25, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(32, 26, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(33, 31, 4, 1, 'pichanga_renotify', 'Recordatorio de pichanga', 'pichanga', '{\"pichanga_id\":1,\"club_id\":4}', 0, NULL, '2026-03-30 07:46:02', '2026-03-30 07:46:02'),
(34, 1, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 1, '2026-03-30 18:40:16', '2026-03-30 23:40:08', '2026-03-30 23:40:16'),
(35, 38, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(36, 3, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(37, 4, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(38, 5, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(39, 6, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(40, 7, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(41, 9, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(42, 10, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(43, 11, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(44, 12, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(45, 13, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(46, 14, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(47, 15, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(48, 16, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(49, 17, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(50, 18, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(51, 19, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(52, 20, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(53, 22, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(54, 23, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(55, 24, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(56, 25, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(57, 26, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(58, 31, 4, 2, 'pichanga_renotify', 'Recordatorio de pichanga', 'Revisa la pichanga y confirma tu asistencia', '{\"pichanga_id\":2,\"club_id\":4}', 0, NULL, '2026-03-30 23:40:08', '2026-03-30 23:40:08'),
(59, 1, 4, 5, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":5,\"club_id\":4}', 1, '2026-04-04 22:59:46', '2026-04-05 00:53:04', '2026-04-05 03:59:46'),
(60, 38, 4, 5, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":5,\"club_id\":4}', 1, '2026-04-05 00:41:51', '2026-04-05 00:53:04', '2026-04-05 05:41:51'),
(61, 1, 4, 6, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":6,\"club_id\":4}', 1, '2026-04-04 19:57:46', '2026-04-05 00:57:30', '2026-04-05 00:57:46'),
(62, 38, 4, 6, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":6,\"club_id\":4}', 0, NULL, '2026-04-05 00:57:30', '2026-04-05 00:57:30'),
(63, 38, 3, NULL, 'challenge_chat_message', 'Nuevo reto recibido', 'Te retaron a una pichanga.', '{\"challenge_id\":1,\"chat_message_id\":1}', 1, '2026-04-05 00:35:00', '2026-04-05 05:34:40', '2026-04-05 05:35:00'),
(64, 1, 4, NULL, 'challenge_chat_message', 'Reto en coordinación', 'ricci está coordinando.', '{\"challenge_id\":1,\"chat_message_id\":2}', 1, '2026-04-05 00:37:11', '2026-04-05 05:37:03', '2026-04-05 05:37:11'),
(65, 1, 4, NULL, 'challenge_chat_message', 'Reto en coordinación', 'ricci está coordinando.', '{\"challenge_id\":1,\"chat_message_id\":7}', 1, '2026-04-05 00:39:10', '2026-04-05 05:39:09', '2026-04-05 05:39:10'),
(66, 1, 4, NULL, 'challenge_configuration_proposed', 'Configuración propuesta', 'Revisa y responde la propuesta del reto.', '{\"challenge_id\":1,\"configuration_id\":1,\"chat_message_id\":12,\"invited_link_enabled\":false}', 1, '2026-04-05 00:41:24', '2026-04-05 05:41:21', '2026-04-05 05:41:24'),
(67, 1, 4, NULL, 'challenge_configuration_accepted', 'Configuración aceptada parcialmente', 'Una parte aceptó. Falta la confirmación final.', '{\"challenge_id\":1,\"configuration_id\":1,\"chat_message_id\":13}', 1, '2026-04-05 00:41:39', '2026-04-05 05:41:37', '2026-04-05 05:41:39'),
(68, 38, 3, NULL, 'challenge_chat_message', 'Reto en coordinación', 'aricci está coordinando.', '{\"challenge_id\":1,\"chat_message_id\":14}', 1, '2026-04-05 00:43:11', '2026-04-05 05:42:09', '2026-04-05 05:43:11'),
(69, 38, 3, 7, 'challenge_confirmed', 'Reto confirmado', 'La pichanga quedó confirmada. Revisa fecha, hora y cancha.', '{\"challenge_id\":1,\"pichanga_id\":7,\"chat_message_id\":15}', 1, '2026-04-05 00:43:11', '2026-04-05 05:42:14', '2026-04-05 05:43:11'),
(70, 1, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 1, '2026-04-05 18:03:23', '2026-04-05 17:23:37', '2026-04-05 23:03:23'),
(71, 38, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(72, 3, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(73, 4, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(74, 5, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(75, 6, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(76, 7, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(77, 9, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(78, 10, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(79, 11, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(80, 12, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(81, 13, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(82, 14, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(83, 15, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(84, 16, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(85, 17, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(86, 18, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(87, 19, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(88, 20, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(89, 22, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(90, 23, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(91, 24, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(92, 25, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(93, 26, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(94, 31, 4, 7, 'pichanga_renotify', 'Recordatorio de pichanga', 'Reto 4 vs 3', '{\"pichanga_id\":7,\"club_id\":4}', 0, NULL, '2026-04-05 17:23:37', '2026-04-05 17:23:37'),
(95, 1, 4, 8, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":8,\"club_id\":4}', 0, NULL, '2026-04-07 17:45:46', '2026-04-07 17:45:46'),
(96, 38, 4, 8, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":8,\"club_id\":4}', 0, NULL, '2026-04-07 17:45:46', '2026-04-07 17:45:46'),
(97, 1, 4, 9, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":9,\"club_id\":4}', 1, '2026-04-07 13:43:10', '2026-04-07 18:42:37', '2026-04-07 18:43:10'),
(98, 38, 4, 9, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":9,\"club_id\":4}', 0, NULL, '2026-04-07 18:42:37', '2026-04-07 18:42:37'),
(99, 1, 4, 10, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":10,\"club_id\":4}', 0, NULL, '2026-04-07 18:44:03', '2026-04-07 18:44:03'),
(100, 38, 4, 10, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":10,\"club_id\":4}', 0, NULL, '2026-04-07 18:44:03', '2026-04-07 18:44:03'),
(101, 38, 3, 11, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":11,\"club_id\":3}', 0, NULL, '2026-04-07 20:06:19', '2026-04-07 20:06:19'),
(102, 1, 3, 12, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":12,\"club_id\":3}', 1, '2026-04-07 20:48:28', '2026-04-08 01:47:27', '2026-04-08 01:48:28'),
(103, 38, 3, 12, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":12,\"club_id\":3}', 0, NULL, '2026-04-08 01:47:27', '2026-04-08 01:47:27'),
(104, 1, 3, 13, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":13,\"club_id\":3}', 1, '2026-04-08 02:16:46', '2026-04-08 07:16:28', '2026-04-08 07:16:46'),
(105, 38, 3, 13, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":13,\"club_id\":3}', 0, NULL, '2026-04-08 07:16:28', '2026-04-08 07:16:28'),
(106, 1, 3, 14, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":14,\"club_id\":3}', 0, NULL, '2026-04-08 07:17:55', '2026-04-08 07:17:55'),
(107, 38, 3, 14, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":14,\"club_id\":3}', 0, NULL, '2026-04-08 07:17:55', '2026-04-08 07:17:55'),
(108, 1, 3, 15, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":15,\"club_id\":3}', 1, '2026-04-08 11:24:59', '2026-04-08 16:24:33', '2026-04-08 16:24:59'),
(109, 38, 3, 15, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":15,\"club_id\":3}', 1, '2026-04-08 11:25:51', '2026-04-08 16:24:33', '2026-04-08 16:25:51'),
(110, 1, 3, 16, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":16,\"club_id\":3}', 0, NULL, '2026-04-08 19:31:28', '2026-04-08 19:31:28'),
(111, 38, 3, 16, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":16,\"club_id\":3}', 0, NULL, '2026-04-08 19:31:28', '2026-04-08 19:31:28'),
(112, 1, 3, 17, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":17,\"club_id\":3}', 0, NULL, '2026-04-08 21:12:47', '2026-04-08 21:12:47'),
(113, 38, 3, 17, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":17,\"club_id\":3}', 0, NULL, '2026-04-08 21:12:47', '2026-04-08 21:12:47'),
(114, 1, 3, 18, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":18,\"club_id\":3}', 1, '2026-04-08 18:56:49', '2026-04-08 23:56:37', '2026-04-08 23:56:49'),
(115, 38, 3, 18, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":18,\"club_id\":3}', 0, NULL, '2026-04-08 23:56:37', '2026-04-08 23:56:37'),
(116, 1, 3, 19, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":19,\"club_id\":3}', 0, NULL, '2026-04-09 02:39:40', '2026-04-09 02:39:40'),
(117, 38, 3, 19, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":19,\"club_id\":3}', 0, NULL, '2026-04-09 02:39:40', '2026-04-09 02:39:40'),
(118, 1, 3, 20, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":20,\"club_id\":3}', 0, NULL, '2026-04-09 02:45:56', '2026-04-09 02:45:56'),
(119, 38, 3, 20, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":20,\"club_id\":3}', 0, NULL, '2026-04-09 02:45:56', '2026-04-09 02:45:56'),
(120, 1, 3, 21, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":21,\"club_id\":3}', 0, NULL, '2026-04-09 03:36:37', '2026-04-09 03:36:37'),
(121, 38, 3, 21, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":21,\"club_id\":3}', 0, NULL, '2026-04-09 03:36:37', '2026-04-09 03:36:37'),
(122, 1, 3, 22, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":22,\"club_id\":3}', 0, NULL, '2026-04-09 03:57:35', '2026-04-09 03:57:35'),
(123, 38, 3, 22, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":22,\"club_id\":3}', 0, NULL, '2026-04-09 03:57:35', '2026-04-09 03:57:35'),
(124, 1, 4, 23, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":23,\"club_id\":4}', 0, NULL, '2026-04-09 03:59:03', '2026-04-09 03:59:03'),
(125, 38, 4, 23, 'pichanga_created', 'Nueva pichanga', 'Se creó una pichanga en tu grupo', '{\"pichanga_id\":23,\"club_id\":4}', 0, NULL, '2026-04-09 03:59:03', '2026-04-09 03:59:03');

-- --------------------------------------------------------

--
-- Table structure for table `region`
--

CREATE TABLE `region` (
  `id` int(11) NOT NULL,
  `nombres` varchar(200) DEFAULT NULL,
  `id_pais` int(11) DEFAULT NULL,
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `reporter_user_id` bigint(20) UNSIGNED NOT NULL,
  `target_type` enum('user','field','field_photo','group_pichanga') NOT NULL,
  `target_id` bigint(20) UNSIGNED NOT NULL,
  `reason_code` varchar(60) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `status` enum('pending','reviewed','dismissed','actioned') NOT NULL DEFAULT 'pending',
  `resolved_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `resolution_note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `servicio_polideportivo`
--

CREATE TABLE `servicio_polideportivo` (
  `id` int(11) NOT NULL,
  `nombre` varchar(200) DEFAULT NULL,
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `servicio_polideportivo_detalle`
--

CREATE TABLE `servicio_polideportivo_detalle` (
  `id` int(11) NOT NULL,
  `id_polideportivo` int(11) DEFAULT NULL,
  `id_user_create` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `strikes`
--

CREATE TABLE `strikes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `report_id` bigint(20) UNSIGNED DEFAULT NULL,
  `assigned_by_user_id` bigint(20) UNSIGNED NOT NULL,
  `reason_code` varchar(60) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `status` enum('active','revoked') NOT NULL DEFAULT 'active',
  `expires_at` datetime DEFAULT NULL,
  `revoked_by_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `revoked_note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `nick` varchar(200) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `fec_nac` date DEFAULT NULL,
  `altura_cm` smallint(5) UNSIGNED DEFAULT NULL,
  `estado` varchar(2) DEFAULT '1' COMMENT '1, 0',
  `sexo` varchar(2) DEFAULT NULL COMMENT 'M, F',
  `id_user_create` int(11) DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `auth_provider` varchar(30) DEFAULT NULL,
  `provider_uid` varchar(191) DEFAULT NULL,
  `avatar_url` varchar(500) DEFAULT NULL,
  `suspended_until` datetime DEFAULT NULL,
  `suspension_reason` varchar(255) DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `nick`, `email`, `fec_nac`, `altura_cm`, `estado`, `sexo`, `id_user_create`, `email_verified_at`, `password`, `auth_provider`, `provider_uid`, `avatar_url`, `suspended_until`, `suspension_reason`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Enrique Ricci', 'aricci', 'alfredoenriquericciale@gmail.com', NULL, NULL, '1', 'M', NULL, NULL, '$2y$12$C6FM44JeqN5wvpbhGGOlK.KyTzu9g2p7drHwO1cqzdFOIjUxIHTfS', 'google', '102135978547699259886', 'https://lh3.googleusercontent.com/a/ACg8ocIajhw6Rg0P-shhXSMd_V6qVkvMSfRND3qoywk6_YTjiAgG9nN-=s96-c', NULL, NULL, NULL, '2025-11-05 14:11:41', '2026-03-24 23:15:06'),
(3, 'Jorge Rodriguez', 'jorge', 'jorge@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(4, 'Joaco Paitan', 'joaco', 'joaco@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(5, 'Erick Paucar', 'erick', 'erick@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(6, 'Adrián Espinoza Bartra', 'adrian', 'adrian@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(7, 'Rodrigo Cassia', 'rodrigo', 'rodrigo@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(9, 'Oscar Noriega', 'oscar', 'oscar@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(10, 'Franco Lezama', 'franco', 'francolezama1@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-06 02:16:38'),
(11, 'Brando Patron', 'brando', 'brando@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(12, 'Santiago', 'santiago', 'santiago@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(13, 'Jesús', 'jesus', 'jesus@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(14, 'Sebastian Llamoca', 'sebastian', 'sebastian@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(15, 'Josue Roca', 'josue', 'josue@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 17:57:45'),
(16, 'Gonzalo Pizarro', 'gonzalo', 'gonzalo@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(17, 'Anders Pezo', 'anders', 'anders@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(18, 'Nicolas Castillejo', 'nicolas', 'nicolas@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(19, 'Matias', 'matias', 'matias@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(20, 'Angus', 'angus', 'angus@gmail.com', NULL, NULL, '1', NULL, 1, NULL, '$2y$12$a5WnXn1MuXqPfpBiV6S2Ke6fKqHK89MiHdepVbCOyeNpJHCIIDpIS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 14:45:47', '2025-11-05 14:45:47'),
(22, 'Cesar Oberto Besso', 'cesar', 'cesar@gmail.com', NULL, NULL, '1', NULL, NULL, NULL, '$2y$12$5xsP/sBzDtcgPzN.2kQwPuWd105GVPSw9QrbEwpS00su19QI6KBj2', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 15:56:50', '2025-11-05 15:56:50'),
(23, 'Santiago Ferradas', 'tiago', 'sferradas31@gmail.com', NULL, NULL, '1', NULL, NULL, NULL, '$2y$12$YJCo61vTZAhOAikKWmz6g.gWwL7t7pgCTOsFMoz6oxdGRAzPWTcuS', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 17:16:01', '2025-11-05 17:16:01'),
(24, 'Alejandro Benavides', 'watermelon', 'alejobeno21@hotmail.com', NULL, NULL, '1', NULL, NULL, NULL, '$2y$12$A980FGkBVH9jLMa4PkQVGe95gZnnWKI6yc.JRzdZ8onlAru5QlHDm', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-05 17:51:13', '2025-11-05 17:51:13'),
(25, '⁠Salvador Sevallos', 'salvador', 'salvador@gmail.com', NULL, NULL, '1', NULL, NULL, NULL, '$2y$12$0mACRWPWMFefchCkVDizMuTgbC84KjD3NJaIiM.sDVhdBPIng/6Qa', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-06 01:21:39', '2025-11-06 01:21:39'),
(26, 'Renzo Ramos', 'renzo', 'renzo@gmail.com', NULL, NULL, '1', NULL, NULL, NULL, '$2y$12$q3xwLZjXp217869KW5FrV.PC2OADUQhkHUlIL09KEPzCPEVFsE4LK', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-06 01:22:07', '2025-11-06 01:22:07'),
(29, 'Fabian Medrano', 'fabianmo', 'fabianmedrano.fmo@gmail.com', NULL, NULL, '1', NULL, NULL, NULL, '$2y$12$upN46svsNbHjDF4u18kpBe31RJipb3mgMqELMClmBweEYTZwtFdWe', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-12 02:24:31', '2025-11-12 02:24:31'),
(30, 'nuevo', 'nuevo2', 'nuevo2@nuevo.com', NULL, NULL, '1', NULL, NULL, NULL, '$2y$12$EeC3RkZpzs2OYnwhaiYl0.hWHfuq9ekBFeoj1Mdusg.83ySTE3JIi', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-12 02:34:17', '2025-11-12 02:34:17'),
(31, 'juanjo', 'juanjo', 'juanjo@gmail.com', NULL, NULL, '1', NULL, NULL, NULL, '$2y$12$Qp.NNC9Fy9YLLM0RM4L45OhRc52gY8LD/d/nqC3itvYt4H.Y9y8hO', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-21 17:56:17', '2025-11-21 17:56:17'),
(38, 'Apple User', 'ricci', 'alfredoenriquericciale@hotmail.com', NULL, NULL, '1', 'M', NULL, NULL, '$2y$12$xJVjv7.IofDVhiLQuqW3Oe3jubYWkrCms6uqbagbrOdvKbJt4GXr6', 'apple', '001323.f2155a07260f46629151d700eb2d1350.1835', NULL, NULL, NULL, NULL, '2026-03-24 20:37:42', '2026-03-24 20:49:18'),
(39, 'tinq', '12345', 'contacto.tinq@gmail.com', NULL, NULL, '1', 'M', NULL, NULL, '$2y$12$Cyckqr89e7bvlwr8gStBVOJVZ4GC2fi8SHXS6kukWDjoPGnUkgTyi', 'google', '105412478790875641900', 'https://lh3.googleusercontent.com/a/ACg8ocLQ7kTKuAMVGkbtL6_XdNt49wTu2OH-KvqHtVZWpRVstl09nx8=s96-c', NULL, NULL, NULL, '2026-04-05 23:09:51', '2026-04-05 23:10:28');

-- --------------------------------------------------------

--
-- Table structure for table `user_chat_presence`
--

CREATE TABLE `user_chat_presence` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `challenge_id` bigint(20) UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 0,
  `last_heartbeat_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `user_chat_presence`
--

INSERT INTO `user_chat_presence` (`id`, `user_id`, `challenge_id`, `is_active`, `last_heartbeat_at`, `created_at`, `updated_at`) VALUES
(1, 38, 1, 1, '2026-04-05 00:43:11', '2026-04-05 05:35:00', '2026-04-05 05:43:11'),
(2, 1, 1, 1, '2026-04-05 18:05:21', '2026-04-05 05:37:11', '2026-04-05 23:05:21');

-- --------------------------------------------------------

--
-- Table structure for table `user_devices`
--

CREATE TABLE `user_devices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `platform` enum('ios','android','web') NOT NULL,
  `device_token` varchar(255) NOT NULL,
  `device_name` varchar(100) DEFAULT NULL,
  `app_version` varchar(40) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `last_seen_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `user_devices`
--

INSERT INTO `user_devices` (`id`, `user_id`, `platform`, `device_token`, `device_name`, `app_version`, `is_active`, `last_seen_at`, `created_at`, `updated_at`) VALUES
(1, 1, 'android', 'cPfeeniDT7-0osFP4IQzwO:APA91bFkiRGnA5cXmBeTAi0BBirePkTxxPNIdA3MH8u9rJXXY55JYlxZ-aYeKtjt2v_VG1vT0gnkYwSkBpStuFuWfN9fYdJavtCluYKQtdFO2y5QGLtvGOs', 'android-device', '1.0.0', 1, '2026-03-24 22:55:51', '2026-03-25 01:29:55', '2026-03-25 03:55:51'),
(2, 1, 'ios', 'esznx02fdk0Fohs_F1RAm5:APA91bHWaee5sObvMpxeuewGZW-k4oZyjxKZeT27phmSmo8zR3wVjak6858xgN_VCF19Jm74ONcdnLyCkdXgls1ntFDc_rAybkhf8S8Zh5gE0vfxaAaLiIY', 'ios-device', '1.0.0', 1, '2026-03-29 03:38:16', '2026-03-29 08:32:37', '2026-03-29 08:38:16'),
(3, 38, 'ios', 'dbE0OvmjckuPpsWudxo80b:APA91bF6CK4UlPg7cxihDC955R6hl-GCGWbcdaoiaYjWRYjCgPfCgxZTFRzM6qIpDJn3QzjxXK4Jl50xBjsZJKs2oBZw1dbWjpOKhn62mZ7GllbLoRvJGVs', 'ios-device', '1.0.0', 1, '2026-03-29 03:38:27', '2026-03-29 08:32:50', '2026-03-29 08:38:27'),
(4, 1, 'ios', 'dMSUIgeThEiinLglDVfDtf:APA91bF-Q6YNimS1Z3Q_ygg20RDuX8wYfHRDA6v9ZKFZu9gmH3-hq4UVde1DtNGOW0bnozbCVy5VCR36YXJGyqj7axEp3TMIpYvGRjDu_5pAJ8vnZrXnHWQ', 'ios-device', '1.0.0', 1, '2026-03-29 10:01:55', '2026-03-29 10:06:30', '2026-03-29 15:01:55'),
(5, 38, 'ios', 'eqVRIi6RlUdIm3zPGpg2xQ:APA91bFd5Pl1qcQszgv3mMX6xl6PsF8cCfWqU7wiQQIxmKiYzv6ifH3erUDbO6RgUOFD4qhuCsM3lX-j4LleOBlmvKpVi0qI5ZJJgd7Bu5GOdX8pF3_VlnE', 'ios-device', '1.0.0', 1, '2026-03-29 09:47:37', '2026-03-29 10:08:17', '2026-03-29 14:47:37'),
(6, 38, 'ios', 'fJTwglmW4ERxqHC0CCkqSX:APA91bHHrW8i2slzPrS540PLx8ERVKq8OJeN8Sxmwvpj5QwuwVpzWY68Ewv0RmB913hoL4IUYhd61SZEsjG7NxUqSXaKuPtwvK-nuVX9R4Qcs9vCCHhgMEo', 'ios-device', '1.0.0', 1, '2026-03-29 16:52:27', '2026-03-29 16:12:25', '2026-03-29 21:52:27'),
(7, 1, 'ios', 'dGcsquVTUEYZoiFsoAQuyy:APA91bHAAp2izi8upFVPmX5hogWa7g75BzxAgg4DA1F_GuiAULFIzhgkSEZEWIHExatB2udaJEcG75Oq4Z6nGEJIerHrqQkdWUH_k8jw58GBPDqCivnLvyA', 'ios-device', '1.0.0', 1, '2026-03-29 20:33:03', '2026-03-29 16:12:26', '2026-03-30 01:33:03'),
(8, 1, 'ios', 'dbza4ggQg0ETmXYCNJy38g:APA91bEnYi2MXv1omCDstx5jX_muEkRDINeo9vxMe_69J0UTMQmbfqG9wtyerwQHMEtroUHtxd6irpHk3cskpGqAG-CIJElN_ljX52PY8k7MuXS3oLsPC9I', 'ios-device', '1.0.0', 1, '2026-03-30 02:40:27', '2026-03-30 05:38:17', '2026-03-30 07:40:27'),
(9, 1, 'ios', 'f9leVHe0dkVfrd2a3z00Ku:APA91bEYPoXCZ72qMNyKLhoAmJzFvDUkxPoITtPbnKxLpJ7sYHRo3p9amXVMGr1-UDIqQzeufBcGfGqoX2OnASCwDot520sVk-MqZpnSUMZFRGaJwIiReRQ', 'ios-device', '1.0.0', 1, '2026-03-30 01:04:42', '2026-03-30 05:54:55', '2026-03-30 06:04:42'),
(10, 1, 'ios', 'dovcIXVvaEI_ugswsZxvCU:APA91bFUokRLWG7zHL_8S3Snx_l1QfwrAVdUg2CvGr3P9hoDt1CjUEyl3qZ47ZUJECYrXzBgH4qj9Ulx-TcL_h6AAd4wm9yxT2o67UXGS16XxPWvi7eFPVM', 'ios-device', '1.0.0', 1, '2026-03-30 14:09:22', '2026-03-30 14:28:07', '2026-03-30 19:09:22'),
(11, 38, 'ios', 'c6BK959jKEBauunogR0CfU:APA91bFVilwimEIkX7O-Yyio-v-1-CaUvUGCpuI3JO8LBRZV9EBdVL1phEgEF_0eGmVJvtrmFQrpmGqcrG6_DYDjBsbzlAQ__dRp6RycZT9XA0OBeH74NLU', 'ios-device', '1.0.0', 1, '2026-03-30 13:17:00', '2026-03-30 14:28:12', '2026-03-30 18:17:00'),
(12, 1, 'ios', 'eSkspm2zMU__uALMZVAUCq:APA91bFxgIOgCbXSWIOM5GsUbQaIUR39xHgXbjdNfsUiofqc11V5nMe4n5LFd0Ca3GoRyp4p3FPFqTFX72WQH-UwNChXGuJVjWVmCsQmFDWABJyLRxa9YE0', 'ios-device', '1.0.0', 1, '2026-04-06 19:24:12', '2026-03-30 21:16:58', '2026-04-07 00:24:12'),
(13, 38, 'ios', 'fRsOuMsjlEoXjv6N3_On8b:APA91bFEwDTPW3CgnTBaSEeFA9egykP-EJs4wh48ykUm7CYbOaO90Ki34GcdisGkoxlUU46Rd0aV3N9i5kgcOaEYBdUv9tFiF11I-bhP1Vd45syVwCLpGE0', 'ios-device', '1.0.0', 1, '2026-04-05 12:19:59', '2026-03-30 21:20:49', '2026-04-05 17:19:59'),
(14, 1, 'ios', 'ePcQKf8wzE2aj8Nc-XcB-6:APA91bGi6xKia1wLNKQFU5dKivP3XwHjgHAA_MVp6HmMev-xwUXuJFdFKXfACa64gldKgKdKmxyT8j4t_eZO5Bsv8sskXAYsbueakDP4WqCbpnk_UYgk3Dk', 'ios-device', '1.0.0', 1, '2026-04-07 12:20:19', '2026-04-07 17:17:44', '2026-04-07 17:20:19'),
(15, 1, 'ios', 'fV2-JVrGREariRVqvOXGJl:APA91bE9-wcS7EZSvMsBAtxjtaNLGzKK99_ImePN2rQIGsArXwmdjrGlL0BzmIOB5XbGW-kWrxDXa8SfKw9sfNXEY0IpRX8WdMwpvIncdeEf9rVBduF6fSk', 'ios-device', '1.0.0', 1, '2026-04-08 14:18:43', '2026-04-07 17:36:01', '2026-04-08 19:18:43'),
(16, 38, 'ios', 'dgEPHKoob0z2qEnj5Nu8pc:APA91bG0gazbRLvp2FziY6qVtgTgepq8dis8D71D48bCVTRDK2YluSHwqExlautTWvDiOrGOaAV3kT989pZ4_EZCAkZFeVM-lrCAJXuovkIHlTJRVGHjGmQ', 'ios-device', '1.0.0', 1, '2026-04-07 15:05:31', '2026-04-07 20:05:31', '2026-04-07 20:05:31'),
(17, 38, 'ios', 'e7HKagLCRUJ6rRO5_bTEAV:APA91bHd-btw-Ml2ZgM6ua4PkR0QoLRW0sHoPbJg_zoGOglY_edniGbgHbN1Unh4QcTQg-GV4u4nT_jLIS-k14-pSiV_X51nlaymksyJWEV9uOi1xmpAlyg', 'ios-device', '1.0.0', 1, '2026-04-07 20:51:57', '2026-04-08 01:46:35', '2026-04-08 01:51:57'),
(18, 38, 'ios', 'fk1qYjxwW0JcvJfH_oIPgt:APA91bFPrYjCX2qAowUqigIvucoTBtNJu_l1jMsxqZTSLowXTU3dFGPmtYPsoPmc63gBGIob0eiAx14DizekuYK-0bXYIC3uk3plqLnRecukBCm6XBXH_H0', 'ios-device', '1.0.0', 1, '2026-04-08 12:39:57', '2026-04-08 03:28:51', '2026-04-08 17:39:57'),
(19, 1, 'ios', 'esuq5TqKzkFmuJsI_OIa9K:APA91bGL5dvTwS4jC_uT8-eQQBoASQTy2jx7L5pcaHtysQr1YOjZTLIhi1jN2MeBnHot0EfQD82Sl22k8edIKS7gYC2hBj4nx5pjaP08aK97-vrb6YukoOY', 'ios-device', '1.0.0', 1, '2026-04-08 14:24:53', '2026-04-08 19:24:53', '2026-04-08 19:24:53'),
(20, 38, 'ios', 'dxxZxqwyJkwulIDG3S4GuD:APA91bG050nDldWq4Puf9ikyqip8pkyIkDkASp0Xrs1lVQuHQB3r_7_tWYgCakD8i0D-SfmAW3rHJ_2VLHJs4GO4K1qQ7MXZedUNX8bHScTqKrO6XLEjReo', 'ios-device', '1.0.0', 1, '2026-04-08 14:30:06', '2026-04-08 19:30:06', '2026-04-08 19:30:06'),
(21, 1, 'ios', 'c9FwicVqtUV-rtgATB5RGm:APA91bH2kzaoFzh_rKf4gjIRTsCaBr3Xnkd35y9sjYVI6rrv19CKn_dzdUimFhIdym6iGBFxeXLAPicERBspFymNlEcpB-QfVJb9HS6uL9M1eUegkNnIEVs', 'ios-device', '1.0.0', 1, '2026-04-08 16:10:44', '2026-04-08 21:10:44', '2026-04-08 21:10:44'),
(22, 38, 'ios', 'dqwTIPAYsk8RpchNmEdP3W:APA91bGmKEIVQMpj_RaFDQzmvU7PP2xE3oTPUFy7a9CA3sfdNUOukoNXz1Adb9UlmeHHCQ06vB3kff5STapbJFzUk47mAFIymxtOVUA4AUJG0KDVZDiz4aE', 'ios-device', '1.0.0', 1, '2026-04-08 16:11:18', '2026-04-08 21:11:18', '2026-04-08 21:11:18'),
(23, 1, 'ios', 'ftI6M46Q3k3LjJ6mEmUyQp:APA91bHopIQjXvheadnkdC_yrFa5IpTyQsZwy7ORSJ8UiNDyHLDpoIESgJXIa4pvi0jEbMQ5Ym5SSk96z5CjEOZ0l3NyV8Oyz40yTquGTEcSPY0oH6qVsr8', 'ios-device', '1.0.0', 1, '2026-04-08 18:48:07', '2026-04-08 23:48:07', '2026-04-08 23:48:07'),
(24, 1, 'ios', 'fgmXxN8q-0aJuQEPH6GDND:APA91bEIxkqr5pjPjfG9-nhcSoWPix8I3TWejVtorSfN7qNyskcMzyk4sQFQ_0tZMMvNppe4iTmEb3UYqt85FTy1Kjm0dNuYj_9BzR7gZqWtmkCFNtCzfdw', 'ios-device', '1.0.0', 1, '2026-04-08 19:02:58', '2026-04-08 23:55:53', '2026-04-09 00:02:58'),
(25, 1, 'ios', 'fPgC3YpTW07wpaqKXPzq_9:APA91bFAyU6SVhRHp1ACzc1Wbt2JSkQSfD2vThRc2bGrp9XyejkNKUQ0Iz8bDahOUvyywj87IIEjTsFh247QVYJ1R6iuFYhDVyISfT3W4S2mMlYyogD9XMA', 'ios-device', '1.0.0', 1, '2026-04-08 19:14:57', '2026-04-09 00:13:54', '2026-04-09 00:14:57'),
(26, 1, 'ios', 'cz2Ci6zZU02uqK2nNmH4Et:APA91bHWPX0EyLM3DjJ1-rc9eYBYMGqi03GvY56W-o0Q-Acfa5ZkYU_mnjzN2pB5zeIBzBb3BazoOcyB_4LaZPbpZBX3vLh4pnVENRVTPpiFofwPFNKi--E', 'ios-device', '1.0.0', 1, '2026-04-08 22:02:27', '2026-04-09 02:39:08', '2026-04-09 03:02:27'),
(27, 1, 'ios', 'cFMTsDURoEnqmlgZG6sH_a:APA91bG63cA8L0Dm-hjiOdhayuyUeBVpVyH2c18wK1ycLbEQaYO6YP-mL0AmQWZLzgaCf9l2a4IBJBuOwxy5vd27PAtUxawC8g5a34q7ZG-Q4aurB69rCq0', 'ios-device', '1.0.0', 1, '2026-04-08 22:34:17', '2026-04-09 03:34:17', '2026-04-09 03:34:17');

-- --------------------------------------------------------

--
-- Table structure for table `user_favorite_fields`
--

CREATE TABLE `user_favorite_fields` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `polideportivo_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `user_favorite_fields`
--

INSERT INTO `user_favorite_fields` (`id`, `user_id`, `polideportivo_id`, `created_at`, `updated_at`) VALUES
(1, 1, 1, '2026-03-30 06:02:06', '2026-03-30 06:02:06');

-- --------------------------------------------------------

--
-- Table structure for table `user_group_notification_prefs`
--

CREATE TABLE `user_group_notification_prefs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `club_id` bigint(20) UNSIGNED NOT NULL,
  `mode` enum('always_on','mute_24h','mute_1w','mute_forever') NOT NULL DEFAULT 'always_on',
  `muted_until` timestamp NULL DEFAULT NULL,
  `updated_by_user` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `user_perfil`
--

CREATE TABLE `user_perfil` (
  `id` int(11) NOT NULL,
  `id_user` bigint(20) UNSIGNED NOT NULL,
  `id_perfil` int(11) DEFAULT NULL,
  `estado` varchar(2) DEFAULT '1' COMMENT '0,1',
  `id_user_create` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `user_perfil`
--

INSERT INTO `user_perfil` (`id`, `id_user`, `id_perfil`, `estado`, `id_user_create`, `created_at`, `updated_at`) VALUES
(1, 1, 1, '1', 1, '2025-11-05 14:13:55', '2025-11-05 14:13:55');

-- --------------------------------------------------------

--
-- Table structure for table `user_profile_clips`
--

CREATE TABLE `user_profile_clips` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(120) DEFAULT NULL,
  `mp4_url` varchar(500) NOT NULL,
  `duration_ms` int(10) UNSIGNED NOT NULL DEFAULT 7000,
  `width` smallint(5) UNSIGNED DEFAULT NULL,
  `height` smallint(5) UNSIGNED DEFAULT NULL,
  `has_audio` tinyint(1) NOT NULL DEFAULT 1,
  `file_size_bytes` int(10) UNSIGNED DEFAULT NULL,
  `sort_order` smallint(5) UNSIGNED NOT NULL DEFAULT 1,
  `status` enum('active','deleted') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `user_profile_clips`
--

INSERT INTO `user_profile_clips` (`id`, `user_id`, `title`, `mp4_url`, `duration_ms`, `width`, `height`, `has_audio`, `file_size_bytes`, `sort_order`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, '', 'https://fulbii.com/storage/profile_clips/1/OGj4MPoFnyyt16ApVEh2uSFy2F46cvRoY1IfQlqA.mp4', 7000, 872, 1404, 1, 3589402, 1, 'deleted', '2026-03-30 05:53:18', '2026-03-30 07:40:44'),
(2, 1, '', 'https://fulbii.com/storage/profile_clips/1/eFAJcpy4cbc3RRuPqnpHXgreyMWbygstzx3LlI1k.mp4', 7000, 540, 960, 1, 378796, 1, 'deleted', '2026-03-30 15:43:14', '2026-03-30 16:29:18'),
(3, 1, '', 'https://fulbii.com/storage/profile_clips/1/u5QlPtx7tB8ZuFcWxmVItopZs26W2ff78PYIHQ1f.mp4', 7000, 720, 1280, 1, 740291, 1, 'active', '2026-03-30 16:29:33', '2026-03-30 16:29:33');

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_club_jugador_promedios_publicos`
-- (See below for the actual view)
--
CREATE TABLE `vw_club_jugador_promedios_publicos` (
`club_id` bigint(20) unsigned
,`user_id` bigint(20) unsigned
,`votos` bigint(21)
,`fisico_prom` decimal(7,5)
,`arquero_prom` decimal(7,5)
,`delantero_prom` decimal(7,5)
,`mediocampo_prom` decimal(7,5)
,`defensa_prom` decimal(7,5)
,`posicion_sugerida` varchar(10)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_club_jugador_promedios_todo`
-- (See below for the actual view)
--
CREATE TABLE `vw_club_jugador_promedios_todo` (
`club_id` bigint(20) unsigned
,`user_id` bigint(20) unsigned
,`votos_total` bigint(21)
,`votos_publicos` decimal(22,0)
,`fisico_prom_todo` decimal(7,5)
,`arquero_prom_todo` decimal(7,5)
,`delantero_prom_todo` decimal(7,5)
,`mediocampo_prom_todo` decimal(7,5)
,`defensa_prom_todo` decimal(7,5)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_skill_ratings_avg_by_club`
-- (See below for the actual view)
--
CREATE TABLE `vw_skill_ratings_avg_by_club` (
`club_id` bigint(20) unsigned
,`user_id` bigint(20) unsigned
,`votos` bigint(21)
,`fisico_prom` decimal(7,5)
,`arquero_prom` decimal(7,5)
,`delantero_prom` decimal(7,5)
,`mediocampo_prom` decimal(7,5)
,`defensa_prom` decimal(7,5)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_skill_ratings_avg_global`
-- (See below for the actual view)
--
CREATE TABLE `vw_skill_ratings_avg_global` (
`user_id` bigint(20) unsigned
,`votos` bigint(21)
,`fisico_prom` decimal(7,5)
,`arquero_prom` decimal(7,5)
,`delantero_prom` decimal(7,5)
,`mediocampo_prom` decimal(7,5)
,`defensa_prom` decimal(7,5)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_skill_ratings_votes`
-- (See below for the actual view)
--
CREATE TABLE `vw_skill_ratings_votes` (
`club_id` bigint(20) unsigned
,`user_id` bigint(20) unsigned
,`fisico` decimal(3,1)
,`arquero` decimal(3,1)
,`delantero` decimal(3,1)
,`mediocampo` decimal(3,1)
,`defensa` decimal(3,1)
,`created_at` timestamp
);

-- --------------------------------------------------------

--
-- Table structure for table `watch_match_events`
--

CREATE TABLE `watch_match_events` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `session_id` bigint(20) UNSIGNED NOT NULL,
  `event_type` enum('goal','assist','pause','resume','side_change') NOT NULL,
  `event_at` datetime NOT NULL,
  `minute` smallint(5) UNSIGNED DEFAULT NULL,
  `clock_time` varchar(20) DEFAULT NULL,
  `metadata_json` longtext DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `watch_match_sessions`
--

CREATE TABLE `watch_match_sessions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `external_session_id` varchar(64) DEFAULT NULL,
  `group_pichanga_id` bigint(20) UNSIGNED DEFAULT NULL,
  `field_id` int(10) UNSIGNED DEFAULT NULL,
  `cancha_id` int(10) UNSIGNED DEFAULT NULL,
  `field_geometry_id` bigint(20) UNSIGNED DEFAULT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime DEFAULT NULL,
  `status` enum('idle','live','paused','finished','auto_finished') NOT NULL DEFAULT 'live',
  `my_goal_side` enum('north','south','east','west','unknown') NOT NULL DEFAULT 'unknown',
  `device` enum('watchos','wearos') NOT NULL DEFAULT 'watchos',
  `source` enum('live','simulated') NOT NULL DEFAULT 'live',
  `distance_meters` decimal(10,2) DEFAULT NULL,
  `distance_meters_raw` decimal(10,2) DEFAULT NULL,
  `distance_meters_filtered` decimal(10,2) DEFAULT NULL,
  `device_payload_json` longtext DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `watch_match_sessions`
--

INSERT INTO `watch_match_sessions` (`id`, `user_id`, `external_session_id`, `group_pichanga_id`, `field_id`, `cancha_id`, `field_geometry_id`, `start_time`, `end_time`, `status`, `my_goal_side`, `device`, `source`, `distance_meters`, `distance_meters_raw`, `distance_meters_filtered`, `device_payload_json`, `created_at`, `updated_at`) VALUES
(1, 1, NULL, 6, NULL, NULL, NULL, '2026-04-06 23:54:28', NULL, 'live', 'unknown', 'watchos', 'simulated', NULL, NULL, NULL, NULL, '2026-04-07 00:24:28', '2026-04-07 00:24:28'),
(67, 1, NULL, 19, NULL, NULL, NULL, '2026-04-09 03:25:38', NULL, 'live', 'unknown', 'watchos', 'simulated', NULL, NULL, NULL, NULL, '2026-04-09 03:55:39', '2026-04-09 03:55:39');

-- --------------------------------------------------------

--
-- Table structure for table `watch_position_samples`
--

CREATE TABLE `watch_position_samples` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `session_id` bigint(20) UNSIGNED NOT NULL,
  `sampled_at` datetime NOT NULL,
  `lat` decimal(11,7) NOT NULL,
  `lng` decimal(11,7) NOT NULL,
  `horizontal_accuracy` decimal(8,2) DEFAULT NULL,
  `speed` decimal(8,2) DEFAULT NULL,
  `quality_flag` enum('good','weak','rejected') DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Structure for view `vw_club_jugador_promedios_publicos`
--
DROP TABLE IF EXISTS `vw_club_jugador_promedios_publicos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_club_jugador_promedios_publicos`  AS  select `t`.`club_id` AS `club_id`,`t`.`user_calificado_id` AS `user_id`,count(0) AS `votos`,avg(`t`.`fisico`) AS `fisico_prom`,avg(`t`.`arquero`) AS `arquero_prom`,avg(`t`.`delantero`) AS `delantero_prom`,avg(`t`.`mediocampo`) AS `mediocampo_prom`,avg(`t`.`defensa`) AS `defensa_prom`,case when greatest(avg(`t`.`arquero`),avg(`t`.`delantero`),avg(`t`.`mediocampo`),avg(`t`.`defensa`)) = avg(`t`.`arquero`) then 'Arquero' when greatest(avg(`t`.`arquero`),avg(`t`.`delantero`),avg(`t`.`mediocampo`),avg(`t`.`defensa`)) = avg(`t`.`delantero`) then 'Delantero' when greatest(avg(`t`.`arquero`),avg(`t`.`delantero`),avg(`t`.`mediocampo`),avg(`t`.`defensa`)) = avg(`t`.`mediocampo`) then 'Mediocampo' else 'Defensa' end AS `posicion_sugerida` from `calificaciones` `t` where `t`.`deleted_at` is null and `t`.`ocultada_por_calificado_at` is null and `t`.`silenciada_por_admin_at` is null group by `t`.`club_id`,`t`.`user_calificado_id` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_club_jugador_promedios_todo`
--
DROP TABLE IF EXISTS `vw_club_jugador_promedios_todo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_club_jugador_promedios_todo`  AS  select `t`.`club_id` AS `club_id`,`t`.`user_calificado_id` AS `user_id`,count(0) AS `votos_total`,sum(case when `t`.`ocultada_por_calificado_at` is null and `t`.`silenciada_por_admin_at` is null and `t`.`deleted_at` is null then 1 else 0 end) AS `votos_publicos`,avg(`t`.`fisico`) AS `fisico_prom_todo`,avg(`t`.`arquero`) AS `arquero_prom_todo`,avg(`t`.`delantero`) AS `delantero_prom_todo`,avg(`t`.`mediocampo`) AS `mediocampo_prom_todo`,avg(`t`.`defensa`) AS `defensa_prom_todo` from `calificaciones` `t` where `t`.`deleted_at` is null group by `t`.`club_id`,`t`.`user_calificado_id` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_skill_ratings_avg_by_club`
--
DROP TABLE IF EXISTS `vw_skill_ratings_avg_by_club`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_skill_ratings_avg_by_club`  AS  select `v`.`club_id` AS `club_id`,`v`.`user_id` AS `user_id`,count(0) AS `votos`,avg(`v`.`fisico`) AS `fisico_prom`,avg(`v`.`arquero`) AS `arquero_prom`,avg(`v`.`delantero`) AS `delantero_prom`,avg(`v`.`mediocampo`) AS `mediocampo_prom`,avg(`v`.`defensa`) AS `defensa_prom` from `vw_skill_ratings_votes` `v` where `v`.`club_id` is not null group by `v`.`club_id`,`v`.`user_id` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_skill_ratings_avg_global`
--
DROP TABLE IF EXISTS `vw_skill_ratings_avg_global`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_skill_ratings_avg_global`  AS  select `v`.`user_id` AS `user_id`,count(0) AS `votos`,avg(`v`.`fisico`) AS `fisico_prom`,avg(`v`.`arquero`) AS `arquero_prom`,avg(`v`.`delantero`) AS `delantero_prom`,avg(`v`.`mediocampo`) AS `mediocampo_prom`,avg(`v`.`defensa`) AS `defensa_prom` from `vw_skill_ratings_votes` `v` group by `v`.`user_id` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_skill_ratings_votes`
--
DROP TABLE IF EXISTS `vw_skill_ratings_votes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_skill_ratings_votes`  AS  select `c`.`club_id` AS `club_id`,`c`.`user_calificado_id` AS `user_id`,`c`.`fisico` AS `fisico`,`c`.`arquero` AS `arquero`,`c`.`delantero` AS `delantero`,`c`.`mediocampo` AS `mediocampo`,`c`.`defensa` AS `defensa`,`c`.`created_at` AS `created_at` from `calificaciones` `c` where `c`.`deleted_at` is null union all select `gp`.`club_id` AS `club_id`,`gpr`.`rated_user_id` AS `user_id`,`gpr`.`fisico` AS `fisico`,`gpr`.`arquero` AS `arquero`,`gpr`.`delantero` AS `delantero`,`gpr`.`mediocampo` AS `mediocampo`,`gpr`.`defensa` AS `defensa`,`gpr`.`created_at` AS `created_at` from (`group_pichanga_ratings` `gpr` join `group_pichangas` `gp` on(`gp`.`id` = `gpr`.`pichanga_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `calificaciones`
--
ALTER TABLE `calificaciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_calif_target` (`club_id`,`user_calificado_id`),
  ADD KEY `idx_calif_rater` (`club_id`,`user_calificador_id`),
  ADD KEY `idx_calif_visibilidad` (`user_calificado_id`,`ocultada_por_calificado_at`,`silenciada_por_admin_at`,`deleted_at`),
  ADD KEY `idx_calif_week_lookup` (`club_id`,`user_calificador_id`,`user_calificado_id`,`created_at`);

--
-- Indexes for table `cancha`
--
ALTER TABLE `cancha`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_cancha_poli` (`id_polideportivo`),
  ADD KEY `idx_cancha_tipo_superficie` (`tipo_superficie`),
  ADD KEY `idx_cancha_formato_vs` (`formato_vs`);

--
-- Indexes for table `clubs`
--
ALTER TABLE `clubs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD UNIQUE KEY `uq_clubs_join_code` (`join_code`),
  ADD KEY `fk_clubs_created_by` (`created_by`);

--
-- Indexes for table `club_challenges`
--
ALTER TABLE `club_challenges`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_cc_status_expires` (`status`,`expires_at`),
  ADD KEY `idx_cc_challenger_status` (`challenger_club_id`,`status`,`created_at`),
  ADD KEY `idx_cc_challenged_status` (`challenged_club_id`,`status`,`created_at`),
  ADD KEY `idx_cc_confirmed_pichanga` (`confirmed_pichanga_id`),
  ADD KEY `fk_cc_created_by` (`created_by_user_id`),
  ADD KEY `fk_cc_coord_challenger` (`coordinator_challenger_user_id`),
  ADD KEY `fk_cc_coord_challenged` (`coordinator_challenged_user_id`),
  ADD KEY `fk_cc_rejected_by` (`rejected_by_user_id`),
  ADD KEY `fk_cc_cancelled_by` (`cancelled_by_user_id`);

--
-- Indexes for table `club_challenge_configurations`
--
ALTER TABLE `club_challenge_configurations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_cccfg_challenge_status` (`challenge_id`,`status`,`id`),
  ADD KEY `fk_cccfg_proposed_by` (`proposed_by_user_id`),
  ADD KEY `fk_cccfg_field_option` (`field_option_id`),
  ADD KEY `fk_cccfg_time_option` (`time_option_id`),
  ADD KEY `fk_cccfg_rejected_by` (`rejected_by_user_id`);

--
-- Indexes for table `club_challenge_field_options`
--
ALTER TABLE `club_challenge_field_options`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ccfo_challenge_status` (`challenge_id`,`status`,`id`),
  ADD KEY `fk_ccfo_proposed_by` (`proposed_by_user_id`);

--
-- Indexes for table `club_challenge_messages`
--
ALTER TABLE `club_challenge_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ccm_challenge_id` (`challenge_id`,`id`),
  ADD KEY `idx_ccm_sender_id` (`sender_user_id`,`id`);

--
-- Indexes for table `club_challenge_time_options`
--
ALTER TABLE `club_challenge_time_options`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ccto_challenge_status` (`challenge_id`,`status`,`starts_at`),
  ADD KEY `fk_ccto_proposed_by` (`proposed_by_user_id`);

--
-- Indexes for table `club_invitations`
--
ALTER TABLE `club_invitations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `fk_inv_club` (`club_id`),
  ADD KEY `fk_inv_user` (`invited_user_id`),
  ADD KEY `fk_inv_byuser` (`invited_by_user_id`);

--
-- Indexes for table `club_join_requests`
--
ALTER TABLE `club_join_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_cjr_club_status` (`club_id`,`status`,`created_at`),
  ADD KEY `idx_cjr_requester_status` (`requester_user_id`,`status`,`created_at`),
  ADD KEY `idx_cjr_club_requester_status` (`club_id`,`requester_user_id`,`status`),
  ADD KEY `fk_cjr_decider` (`decided_by_user_id`);

--
-- Indexes for table `club_user`
--
ALTER TABLE `club_user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_club_user` (`club_id`,`user_id`),
  ADD KEY `idx_cu_user` (`user_id`);

--
-- Indexes for table `distritos`
--
ALTER TABLE `distritos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_dist_prov` (`id_provincia`),
  ADD KEY `idx_dist_creator` (`id_user_create`);

--
-- Indexes for table `equipos`
--
ALTER TABLE `equipos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_eq_form` (`id_formacion`);

--
-- Indexes for table `evento`
--
ALTER TABLE `evento`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_event_cancha` (`id_cancha`),
  ADD KEY `idx_event_creator` (`id_user_create`);

--
-- Indexes for table `evento_usuarios`
--
ALTER TABLE `evento_usuarios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_eu_event` (`id_evento`),
  ADD KEY `idx_eu_user` (`id_user_asistente`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `field_geometries`
--
ALTER TABLE `field_geometries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_field_geom_cancha` (`cancha_id`),
  ADD KEY `idx_field_geom_field` (`field_id`);

--
-- Indexes for table `field_submissions`
--
ALTER TABLE `field_submissions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_fs_status_created` (`status`,`created_at`),
  ADD KEY `idx_fs_user_created` (`user_id`,`created_at`);

--
-- Indexes for table `field_submission_photos`
--
ALTER TABLE `field_submission_photos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_fsp_submission_status` (`field_submission_id`,`status`);

--
-- Indexes for table `formacion`
--
ALTER TABLE `formacion`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `goles`
--
ALTER TABLE `goles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_gol_pich` (`id_pichanga`),
  ADD KEY `idx_gol_user` (`id_user_gol`);

--
-- Indexes for table `group_pichangas`
--
ALTER TABLE `group_pichangas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_gp_invited_link_code` (`invited_link_code`),
  ADD KEY `idx_gp_club_starts` (`club_id`,`starts_at`),
  ADD KEY `idx_gp_status_starts` (`status`,`starts_at`),
  ADD KEY `idx_gp_open_starts` (`is_open`,`starts_at`),
  ADD KEY `fk_gp_creator` (`created_by_user_id`),
  ADD KEY `idx_gp_challenge_id` (`challenge_id`),
  ADD KEY `idx_gp_rival_club_id` (`rival_club_id`);

--
-- Indexes for table `group_pichanga_comments`
--
ALTER TABLE `group_pichanga_comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_gpcomment_post_status_created` (`post_id`,`status`,`created_at`),
  ADD KEY `idx_gpcomment_pichanga_status_created` (`pichanga_id`,`status`,`created_at`),
  ADD KEY `fk_gpcomment_user` (`user_id`);

--
-- Indexes for table `group_pichanga_external_requests`
--
ALTER TABLE `group_pichanga_external_requests`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_gper_pichanga_user` (`pichanga_id`,`user_id`),
  ADD KEY `idx_gper_status` (`pichanga_id`,`status`),
  ADD KEY `fk_gper_user` (`user_id`);

--
-- Indexes for table `group_pichanga_notification_batches`
--
ALTER TABLE `group_pichanga_notification_batches`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_gpb_pichanga_created` (`pichanga_id`,`created_at`),
  ADD KEY `fk_gpb_user` (`triggered_by_user_id`);

--
-- Indexes for table `group_pichanga_participants`
--
ALTER TABLE `group_pichanga_participants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_gpp_pichanga_user` (`pichanga_id`,`user_id`),
  ADD UNIQUE KEY `uq_gpp_team_slot` (`pichanga_id`,`team_code`,`team_slot`),
  ADD KEY `idx_gpp_status` (`pichanga_id`,`status`),
  ADD KEY `fk_gpp_user` (`user_id`),
  ADD KEY `idx_gpp_team_board` (`pichanga_id`,`status`,`team_code`,`team_slot`);

--
-- Indexes for table `group_pichanga_posts`
--
ALTER TABLE `group_pichanga_posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_gppost_pichanga_status_created` (`pichanga_id`,`status`,`created_at`),
  ADD KEY `fk_gppost_user` (`user_id`);

--
-- Indexes for table `group_pichanga_ratings`
--
ALTER TABLE `group_pichanga_ratings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_gprating_pichanga_rater_rated` (`pichanga_id`,`rater_user_id`,`rated_user_id`),
  ADD KEY `idx_gprating_rated_created` (`rated_user_id`,`created_at`),
  ADD KEY `fk_gprating_rater` (`rater_user_id`);

--
-- Indexes for table `historial_calificacion`
--
ALTER TABLE `historial_calificacion`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_hc_userjug` (`id_user_jugador`),
  ADD KEY `idx_hc_pich` (`id_pichanga`),
  ADD KEY `idx_hc_creator` (`id_user_create`);

--
-- Indexes for table `horario_atencion`
--
ALTER TABLE `horario_atencion`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_hor_poli` (`id_polideportivo`),
  ADD KEY `idx_hor_user` (`id_user_create`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_jobs_queue` (`queue`),
  ADD KEY `idx_jobs_reserved` (`reserved_at`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pais`
--
ALTER TABLE `pais`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pais_creator` (`id_user_create`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD KEY `password_resets_email_index` (`email`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `perfil`
--
ALTER TABLE `perfil`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_perfil_creator` (`id_user_create`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `pichanga`
--
ALTER TABLE `pichanga`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pich_event` (`id_evento`),
  ADD KEY `idx_pich_user` (`id_user_asistente`),
  ADD KEY `idx_pich_equipo` (`id_equipo`),
  ADD KEY `idx_pich_pos` (`id_posicion`);

--
-- Indexes for table `polideportivo`
--
ALTER TABLE `polideportivo`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_poli_dist` (`id_distrito`),
  ADD KEY `idx_poli_creator` (`id_user_create`),
  ADD KEY `idx_poli_precio_desde_num` (`precio_desde_num`);

--
-- Indexes for table `posicion`
--
ALTER TABLE `posicion`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pos_form` (`id_formacion`);

--
-- Indexes for table `product_events`
--
ALTER TABLE `product_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pe_event_time` (`event_name`,`happened_at`),
  ADD KEY `idx_pe_user_time` (`user_id`,`happened_at`),
  ADD KEY `idx_pe_club_time` (`club_id`,`happened_at`),
  ADD KEY `idx_pe_pichanga_time` (`pichanga_id`,`happened_at`);

--
-- Indexes for table `provincia`
--
ALTER TABLE `provincia`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_prov_region` (`id_region`),
  ADD KEY `idx_prov_creator` (`id_user_create`);

--
-- Indexes for table `push_dispatch_logs`
--
ALTER TABLE `push_dispatch_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pdl_notification_status` (`push_notification_id`,`status`);

--
-- Indexes for table `push_notifications`
--
ALTER TABLE `push_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pn_user_read_created` (`user_id`,`is_read`,`created_at`),
  ADD KEY `idx_pn_club_created` (`club_id`,`created_at`),
  ADD KEY `idx_pn_pichanga_created` (`group_pichanga_id`,`created_at`);

--
-- Indexes for table `region`
--
ALTER TABLE `region`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_region_pais` (`id_pais`),
  ADD KEY `idx_reg_creator` (`id_user_create`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_reports_status_created` (`status`,`created_at`),
  ADD KEY `idx_reports_target` (`target_type`,`target_id`),
  ADD KEY `idx_reports_reporter_created` (`reporter_user_id`,`created_at`);

--
-- Indexes for table `servicio_polideportivo`
--
ALTER TABLE `servicio_polideportivo`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_sp_user` (`id_user_create`);

--
-- Indexes for table `servicio_polideportivo_detalle`
--
ALTER TABLE `servicio_polideportivo_detalle`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_spd_poli` (`id_polideportivo`),
  ADD KEY `idx_spd_user` (`id_user_create`);

--
-- Indexes for table `strikes`
--
ALTER TABLE `strikes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_strikes_user_status_created` (`user_id`,`status`,`created_at`),
  ADD KEY `idx_strikes_report` (`report_id`),
  ADD KEY `fk_strikes_assigned_by` (`assigned_by_user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD KEY `idx_users_nick` (`nick`);

--
-- Indexes for table `user_chat_presence`
--
ALTER TABLE `user_chat_presence`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_ucp_user` (`user_id`),
  ADD KEY `idx_ucp_challenge_active` (`challenge_id`,`is_active`,`last_heartbeat_at`);

--
-- Indexes for table `user_devices`
--
ALTER TABLE `user_devices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_ud_platform_token` (`platform`,`device_token`),
  ADD KEY `idx_ud_user_active` (`user_id`,`is_active`);

--
-- Indexes for table `user_favorite_fields`
--
ALTER TABLE `user_favorite_fields`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_uff_user_field` (`user_id`,`polideportivo_id`),
  ADD KEY `idx_uff_field_created` (`polideportivo_id`,`created_at`);

--
-- Indexes for table `user_group_notification_prefs`
--
ALTER TABLE `user_group_notification_prefs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_club_notification_pref` (`user_id`,`club_id`),
  ADD KEY `idx_club_mode` (`club_id`,`mode`),
  ADD KEY `idx_muted_until` (`muted_until`);

--
-- Indexes for table `user_perfil`
--
ALTER TABLE `user_perfil`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_perfil` (`id_user`,`id_perfil`),
  ADD KEY `idx_up_user` (`id_user`),
  ADD KEY `idx_up_perfil` (`id_perfil`);

--
-- Indexes for table `user_profile_clips`
--
ALTER TABLE `user_profile_clips`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_upc_user_status_order` (`user_id`,`status`,`sort_order`,`id`);

--
-- Indexes for table `watch_match_events`
--
ALTER TABLE `watch_match_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_watch_events_session_time` (`session_id`,`event_at`),
  ADD KEY `idx_watch_events_session_type_time` (`session_id`,`event_type`,`event_at`);

--
-- Indexes for table `watch_match_sessions`
--
ALTER TABLE `watch_match_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_watch_session_user_created` (`user_id`,`created_at`),
  ADD KEY `idx_watch_session_pichanga` (`group_pichanga_id`),
  ADD KEY `idx_watch_session_field` (`field_id`),
  ADD KEY `idx_watch_session_cancha` (`cancha_id`),
  ADD KEY `idx_watch_session_user_status_created` (`user_id`,`status`,`created_at`),
  ADD KEY `idx_watch_session_user_pichanga_created` (`user_id`,`group_pichanga_id`,`created_at`),
  ADD KEY `fk_watch_session_geometry` (`field_geometry_id`),
  ADD KEY `idx_watch_session_user_ext` (`user_id`,`external_session_id`);

--
-- Indexes for table `watch_position_samples`
--
ALTER TABLE `watch_position_samples`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_watch_samples_session_time` (`session_id`,`sampled_at`),
  ADD KEY `idx_watch_samples_session_quality_time` (`session_id`,`quality_flag`,`sampled_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `calificaciones`
--
ALTER TABLE `calificaciones`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT for table `cancha`
--
ALTER TABLE `cancha`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `clubs`
--
ALTER TABLE `clubs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `club_challenges`
--
ALTER TABLE `club_challenges`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `club_challenge_configurations`
--
ALTER TABLE `club_challenge_configurations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `club_challenge_field_options`
--
ALTER TABLE `club_challenge_field_options`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `club_challenge_messages`
--
ALTER TABLE `club_challenge_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `club_challenge_time_options`
--
ALTER TABLE `club_challenge_time_options`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `club_invitations`
--
ALTER TABLE `club_invitations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `club_join_requests`
--
ALTER TABLE `club_join_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `club_user`
--
ALTER TABLE `club_user`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `distritos`
--
ALTER TABLE `distritos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `equipos`
--
ALTER TABLE `equipos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `evento`
--
ALTER TABLE `evento`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `evento_usuarios`
--
ALTER TABLE `evento_usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `field_geometries`
--
ALTER TABLE `field_geometries`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `field_submissions`
--
ALTER TABLE `field_submissions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `field_submission_photos`
--
ALTER TABLE `field_submission_photos`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `formacion`
--
ALTER TABLE `formacion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `goles`
--
ALTER TABLE `goles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `group_pichangas`
--
ALTER TABLE `group_pichangas`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `group_pichanga_comments`
--
ALTER TABLE `group_pichanga_comments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `group_pichanga_external_requests`
--
ALTER TABLE `group_pichanga_external_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `group_pichanga_notification_batches`
--
ALTER TABLE `group_pichanga_notification_batches`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `group_pichanga_participants`
--
ALTER TABLE `group_pichanga_participants`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `group_pichanga_posts`
--
ALTER TABLE `group_pichanga_posts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `group_pichanga_ratings`
--
ALTER TABLE `group_pichanga_ratings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `historial_calificacion`
--
ALTER TABLE `historial_calificacion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `horario_atencion`
--
ALTER TABLE `horario_atencion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=126;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pais`
--
ALTER TABLE `pais`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `perfil`
--
ALTER TABLE `perfil`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `pichanga`
--
ALTER TABLE `pichanga`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `polideportivo`
--
ALTER TABLE `polideportivo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `posicion`
--
ALTER TABLE `posicion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_events`
--
ALTER TABLE `product_events`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=107;

--
-- AUTO_INCREMENT for table `provincia`
--
ALTER TABLE `provincia`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `push_dispatch_logs`
--
ALTER TABLE `push_dispatch_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=508;

--
-- AUTO_INCREMENT for table `push_notifications`
--
ALTER TABLE `push_notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=126;

--
-- AUTO_INCREMENT for table `region`
--
ALTER TABLE `region`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `servicio_polideportivo`
--
ALTER TABLE `servicio_polideportivo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `servicio_polideportivo_detalle`
--
ALTER TABLE `servicio_polideportivo_detalle`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `strikes`
--
ALTER TABLE `strikes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `user_chat_presence`
--
ALTER TABLE `user_chat_presence`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `user_devices`
--
ALTER TABLE `user_devices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `user_favorite_fields`
--
ALTER TABLE `user_favorite_fields`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_group_notification_prefs`
--
ALTER TABLE `user_group_notification_prefs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_perfil`
--
ALTER TABLE `user_perfil`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_profile_clips`
--
ALTER TABLE `user_profile_clips`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `watch_match_events`
--
ALTER TABLE `watch_match_events`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `watch_match_sessions`
--
ALTER TABLE `watch_match_sessions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=68;

--
-- AUTO_INCREMENT for table `watch_position_samples`
--
ALTER TABLE `watch_position_samples`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `calificaciones`
--
ALTER TABLE `calificaciones`
  ADD CONSTRAINT `fk_calif_club` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`),
  ADD CONSTRAINT `fk_calif_rater_member` FOREIGN KEY (`club_id`,`user_calificador_id`) REFERENCES `club_user` (`club_id`, `user_id`),
  ADD CONSTRAINT `fk_calif_target_member` FOREIGN KEY (`club_id`,`user_calificado_id`) REFERENCES `club_user` (`club_id`, `user_id`);

--
-- Constraints for table `cancha`
--
ALTER TABLE `cancha`
  ADD CONSTRAINT `fk_cancha_poli` FOREIGN KEY (`id_polideportivo`) REFERENCES `polideportivo` (`id`);

--
-- Constraints for table `clubs`
--
ALTER TABLE `clubs`
  ADD CONSTRAINT `fk_clubs_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `club_challenges`
--
ALTER TABLE `club_challenges`
  ADD CONSTRAINT `fk_cc_cancelled_by` FOREIGN KEY (`cancelled_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_cc_challenged_club` FOREIGN KEY (`challenged_club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cc_challenger_club` FOREIGN KEY (`challenger_club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cc_coord_challenged` FOREIGN KEY (`coordinator_challenged_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_cc_coord_challenger` FOREIGN KEY (`coordinator_challenger_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_cc_created_by` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cc_rejected_by` FOREIGN KEY (`rejected_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `club_challenge_configurations`
--
ALTER TABLE `club_challenge_configurations`
  ADD CONSTRAINT `fk_cccfg_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `club_challenges` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cccfg_field_option` FOREIGN KEY (`field_option_id`) REFERENCES `club_challenge_field_options` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cccfg_proposed_by` FOREIGN KEY (`proposed_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cccfg_rejected_by` FOREIGN KEY (`rejected_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_cccfg_time_option` FOREIGN KEY (`time_option_id`) REFERENCES `club_challenge_time_options` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `club_challenge_field_options`
--
ALTER TABLE `club_challenge_field_options`
  ADD CONSTRAINT `fk_ccfo_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `club_challenges` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ccfo_proposed_by` FOREIGN KEY (`proposed_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `club_challenge_messages`
--
ALTER TABLE `club_challenge_messages`
  ADD CONSTRAINT `fk_ccm_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `club_challenges` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ccm_sender` FOREIGN KEY (`sender_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `club_challenge_time_options`
--
ALTER TABLE `club_challenge_time_options`
  ADD CONSTRAINT `fk_ccto_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `club_challenges` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ccto_proposed_by` FOREIGN KEY (`proposed_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `club_invitations`
--
ALTER TABLE `club_invitations`
  ADD CONSTRAINT `fk_inv_byuser` FOREIGN KEY (`invited_by_user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_inv_club` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`),
  ADD CONSTRAINT `fk_inv_user` FOREIGN KEY (`invited_user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `club_join_requests`
--
ALTER TABLE `club_join_requests`
  ADD CONSTRAINT `fk_cjr_club` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cjr_decider` FOREIGN KEY (`decided_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_cjr_requester` FOREIGN KEY (`requester_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `club_user`
--
ALTER TABLE `club_user`
  ADD CONSTRAINT `fk_cu_club` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`),
  ADD CONSTRAINT `fk_cu_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `distritos`
--
ALTER TABLE `distritos`
  ADD CONSTRAINT `fk_dist_creator` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_dist_prov` FOREIGN KEY (`id_provincia`) REFERENCES `provincia` (`id`);

--
-- Constraints for table `equipos`
--
ALTER TABLE `equipos`
  ADD CONSTRAINT `fk_eq_form` FOREIGN KEY (`id_formacion`) REFERENCES `formacion` (`id`);

--
-- Constraints for table `evento`
--
ALTER TABLE `evento`
  ADD CONSTRAINT `fk_event_cancha` FOREIGN KEY (`id_cancha`) REFERENCES `cancha` (`id`),
  ADD CONSTRAINT `fk_event_user` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`);

--
-- Constraints for table `evento_usuarios`
--
ALTER TABLE `evento_usuarios`
  ADD CONSTRAINT `fk_eu_event` FOREIGN KEY (`id_evento`) REFERENCES `evento` (`id`),
  ADD CONSTRAINT `fk_eu_user` FOREIGN KEY (`id_user_asistente`) REFERENCES `users` (`id`);

--
-- Constraints for table `field_submissions`
--
ALTER TABLE `field_submissions`
  ADD CONSTRAINT `fk_fs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `field_submission_photos`
--
ALTER TABLE `field_submission_photos`
  ADD CONSTRAINT `fk_fsp_submission` FOREIGN KEY (`field_submission_id`) REFERENCES `field_submissions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `goles`
--
ALTER TABLE `goles`
  ADD CONSTRAINT `fk_gol_pich` FOREIGN KEY (`id_pichanga`) REFERENCES `pichanga` (`id`),
  ADD CONSTRAINT `fk_gol_user` FOREIGN KEY (`id_user_gol`) REFERENCES `users` (`id`);

--
-- Constraints for table `group_pichangas`
--
ALTER TABLE `group_pichangas`
  ADD CONSTRAINT `fk_gp_challenge_id` FOREIGN KEY (`challenge_id`) REFERENCES `club_challenges` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_gp_club` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gp_creator` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `group_pichanga_comments`
--
ALTER TABLE `group_pichanga_comments`
  ADD CONSTRAINT `fk_gpcomment_pichanga` FOREIGN KEY (`pichanga_id`) REFERENCES `group_pichangas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gpcomment_post` FOREIGN KEY (`post_id`) REFERENCES `group_pichanga_posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gpcomment_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `group_pichanga_external_requests`
--
ALTER TABLE `group_pichanga_external_requests`
  ADD CONSTRAINT `fk_gper_pichanga` FOREIGN KEY (`pichanga_id`) REFERENCES `group_pichangas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gper_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `group_pichanga_notification_batches`
--
ALTER TABLE `group_pichanga_notification_batches`
  ADD CONSTRAINT `fk_gpb_pichanga` FOREIGN KEY (`pichanga_id`) REFERENCES `group_pichangas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gpb_user` FOREIGN KEY (`triggered_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `group_pichanga_participants`
--
ALTER TABLE `group_pichanga_participants`
  ADD CONSTRAINT `fk_gpp_pichanga` FOREIGN KEY (`pichanga_id`) REFERENCES `group_pichangas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gpp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `group_pichanga_posts`
--
ALTER TABLE `group_pichanga_posts`
  ADD CONSTRAINT `fk_gppost_pichanga` FOREIGN KEY (`pichanga_id`) REFERENCES `group_pichangas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gppost_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `group_pichanga_ratings`
--
ALTER TABLE `group_pichanga_ratings`
  ADD CONSTRAINT `fk_gprating_pichanga` FOREIGN KEY (`pichanga_id`) REFERENCES `group_pichangas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gprating_rated` FOREIGN KEY (`rated_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_gprating_rater` FOREIGN KEY (`rater_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `historial_calificacion`
--
ALTER TABLE `historial_calificacion`
  ADD CONSTRAINT `fk_hc_creator` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_hc_pich` FOREIGN KEY (`id_pichanga`) REFERENCES `pichanga` (`id`),
  ADD CONSTRAINT `fk_hc_userjug` FOREIGN KEY (`id_user_jugador`) REFERENCES `users` (`id`);

--
-- Constraints for table `horario_atencion`
--
ALTER TABLE `horario_atencion`
  ADD CONSTRAINT `fk_hor_poli` FOREIGN KEY (`id_polideportivo`) REFERENCES `polideportivo` (`id`),
  ADD CONSTRAINT `fk_hor_user` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`);

--
-- Constraints for table `pais`
--
ALTER TABLE `pais`
  ADD CONSTRAINT `fk_pais_creator` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`);

--
-- Constraints for table `perfil`
--
ALTER TABLE `perfil`
  ADD CONSTRAINT `fk_perfil_creator` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`);

--
-- Constraints for table `pichanga`
--
ALTER TABLE `pichanga`
  ADD CONSTRAINT `fk_pich_equipo` FOREIGN KEY (`id_equipo`) REFERENCES `equipos` (`id`),
  ADD CONSTRAINT `fk_pich_event` FOREIGN KEY (`id_evento`) REFERENCES `evento` (`id`),
  ADD CONSTRAINT `fk_pich_pos` FOREIGN KEY (`id_posicion`) REFERENCES `posicion` (`id`),
  ADD CONSTRAINT `fk_pich_user` FOREIGN KEY (`id_user_asistente`) REFERENCES `users` (`id`);

--
-- Constraints for table `polideportivo`
--
ALTER TABLE `polideportivo`
  ADD CONSTRAINT `fk_poli_dist` FOREIGN KEY (`id_distrito`) REFERENCES `distritos` (`id`),
  ADD CONSTRAINT `fk_poli_user` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`);

--
-- Constraints for table `posicion`
--
ALTER TABLE `posicion`
  ADD CONSTRAINT `fk_pos_form` FOREIGN KEY (`id_formacion`) REFERENCES `formacion` (`id`);

--
-- Constraints for table `provincia`
--
ALTER TABLE `provincia`
  ADD CONSTRAINT `fk_prov_creator` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_prov_region` FOREIGN KEY (`id_region`) REFERENCES `region` (`id`);

--
-- Constraints for table `push_dispatch_logs`
--
ALTER TABLE `push_dispatch_logs`
  ADD CONSTRAINT `fk_pdl_notification` FOREIGN KEY (`push_notification_id`) REFERENCES `push_notifications` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `push_notifications`
--
ALTER TABLE `push_notifications`
  ADD CONSTRAINT `fk_pn_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `region`
--
ALTER TABLE `region`
  ADD CONSTRAINT `fk_reg_creator` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_region_pais` FOREIGN KEY (`id_pais`) REFERENCES `pais` (`id`);

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `fk_reports_reporter` FOREIGN KEY (`reporter_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `servicio_polideportivo`
--
ALTER TABLE `servicio_polideportivo`
  ADD CONSTRAINT `fk_sp_user` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`);

--
-- Constraints for table `servicio_polideportivo_detalle`
--
ALTER TABLE `servicio_polideportivo_detalle`
  ADD CONSTRAINT `fk_spd_poli` FOREIGN KEY (`id_polideportivo`) REFERENCES `polideportivo` (`id`),
  ADD CONSTRAINT `fk_spd_user` FOREIGN KEY (`id_user_create`) REFERENCES `users` (`id`);

--
-- Constraints for table `strikes`
--
ALTER TABLE `strikes`
  ADD CONSTRAINT `fk_strikes_assigned_by` FOREIGN KEY (`assigned_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_strikes_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_chat_presence`
--
ALTER TABLE `user_chat_presence`
  ADD CONSTRAINT `fk_ucp_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `club_challenges` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ucp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_devices`
--
ALTER TABLE `user_devices`
  ADD CONSTRAINT `fk_ud_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_favorite_fields`
--
ALTER TABLE `user_favorite_fields`
  ADD CONSTRAINT `fk_uff_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_group_notification_prefs`
--
ALTER TABLE `user_group_notification_prefs`
  ADD CONSTRAINT `fk_ugnp_club` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ugnp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_perfil`
--
ALTER TABLE `user_perfil`
  ADD CONSTRAINT `fk_up_perfil` FOREIGN KEY (`id_perfil`) REFERENCES `perfil` (`id`),
  ADD CONSTRAINT `fk_up_user` FOREIGN KEY (`id_user`) REFERENCES `users` (`id`);

--
-- Constraints for table `user_profile_clips`
--
ALTER TABLE `user_profile_clips`
  ADD CONSTRAINT `fk_upc_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `watch_match_events`
--
ALTER TABLE `watch_match_events`
  ADD CONSTRAINT `fk_watch_events_session` FOREIGN KEY (`session_id`) REFERENCES `watch_match_sessions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `watch_match_sessions`
--
ALTER TABLE `watch_match_sessions`
  ADD CONSTRAINT `fk_watch_session_geometry` FOREIGN KEY (`field_geometry_id`) REFERENCES `field_geometries` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_watch_session_pichanga` FOREIGN KEY (`group_pichanga_id`) REFERENCES `group_pichangas` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_watch_session_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `watch_position_samples`
--
ALTER TABLE `watch_position_samples`
  ADD CONSTRAINT `fk_watch_samples_session` FOREIGN KEY (`session_id`) REFERENCES `watch_match_sessions` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
