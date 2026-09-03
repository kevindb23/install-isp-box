/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.6.23-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: portal
-- ------------------------------------------------------
-- Server version	10.6.23-MariaDB-0ubuntu0.22.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `portal`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `portal` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;

USE `portal`;

--
-- Table structure for table `activity_logs`
--

DROP TABLE IF EXISTS `activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `activity_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(128) DEFAULT NULL,
  `module` varchar(64) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_activity_user` (`user_id`),
  KEY `idx_activity_date` (`created_at`),
  CONSTRAINT `fk_activity_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `api_logs`
--

DROP TABLE IF EXISTS `api_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `endpoint` varchar(255) DEFAULT NULL,
  `method` varchar(10) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `api_rate_limits`
--

DROP TABLE IF EXISTS `api_rate_limits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_rate_limits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(45) DEFAULT NULL,
  `requests` int(11) DEFAULT NULL,
  `last_request` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `api_tokens`
--

DROP TABLE IF EXISTS `api_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `purpose` varchar(32) NOT NULL DEFAULT 'CUSTOM',
  `scopes` text NOT NULL,
  `transport_policy` varchar(8) NOT NULL DEFAULT 'BOTH',
  `created_by` int(11) DEFAULT NULL,
  `token` varchar(64) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `last_used_ip` varchar(64) DEFAULT NULL,
  `revoked_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_api_tokens_token` (`token`),
  KEY `fk_api_tokens_user` (`user_id`),
  KEY `idx_api_tokens_active` (`revoked_at`,`expires_at`),
  KEY `fk_api_tokens_created_by` (`created_by`),
  CONSTRAINT `fk_api_tokens_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_api_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_api_tokens_transport_policy` CHECK (`transport_policy` in ('HTTPS','HTTP','BOTH'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `audit_logs`
--

DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `actor_role` varchar(50) DEFAULT NULL,
  `module` varchar(100) NOT NULL,
  `action` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `object_type` varchar(100) DEFAULT NULL,
  `object_id` bigint(20) DEFAULT NULL,
  `result` varchar(32) NOT NULL DEFAULT 'SUCCESS',
  `source` varchar(50) NOT NULL DEFAULT 'APPLICATION',
  `http_method` varchar(10) DEFAULT NULL,
  `route` varchar(255) DEFAULT NULL,
  `request_id` varchar(64) DEFAULT NULL,
  `metadata_json` longtext DEFAULT NULL,
  `old_values_json` longtext DEFAULT NULL,
  `new_values_json` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_module` (`module`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_audit_result` (`result`),
  KEY `idx_audit_source` (`source`),
  KEY `idx_audit_request_id` (`request_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16253 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `billing_activity_logs`
--

DROP TABLE IF EXISTS `billing_activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `billing_activity_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `entity_type` varchar(50) NOT NULL,
  `entity_id` bigint(20) unsigned NOT NULL,
  `action` varchar(80) NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'SUCCESS',
  `title` varchar(255) NOT NULL,
  `message` text DEFAULT NULL,
  `old_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`old_values`)),
  `new_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`new_values`)),
  `meta_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`meta_json`)),
  `performed_by` bigint(20) unsigned DEFAULT NULL,
  `performed_by_name` varchar(150) DEFAULT NULL,
  `ip_address` varchar(64) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_billing_activity_entity` (`entity_type`,`entity_id`),
  KEY `idx_billing_activity_action` (`action`),
  KEY `idx_billing_activity_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `billing_adjustments`
--

DROP TABLE IF EXISTS `billing_adjustments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `billing_adjustments` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `adjustment_no` varchar(50) NOT NULL,
  `invoice_id` bigint(20) unsigned NOT NULL,
  `subscriber_id` bigint(20) unsigned DEFAULT NULL,
  `service_id` bigint(20) unsigned DEFAULT NULL,
  `adjustment_type` enum('CREDIT','DEBIT','DISCOUNT','REBATE','WAIVER','CORRECTION') NOT NULL DEFAULT 'CREDIT',
  `amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `reason` text DEFAULT NULL,
  `status` enum('POSTED','VOIDED','PENDING') NOT NULL DEFAULT 'POSTED',
  `created_by` bigint(20) unsigned DEFAULT NULL,
  `approved_by` bigint(20) unsigned DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `voided_by` bigint(20) unsigned DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `void_reason` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `adjustment_no` (`adjustment_no`),
  KEY `idx_billing_adjustments_invoice_id` (`invoice_id`),
  KEY `idx_billing_adjustments_subscriber_id` (`subscriber_id`),
  KEY `idx_billing_adjustments_service_id` (`service_id`),
  KEY `idx_billing_adjustments_status` (`status`),
  KEY `idx_billing_adjustments_type` (`adjustment_type`),
  KEY `idx_billing_adjustments_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `billing_run_items`
--

DROP TABLE IF EXISTS `billing_run_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `billing_run_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `billing_run_id` int(11) NOT NULL,
  `service_id` int(11) DEFAULT NULL,
  `subscriber_id` int(11) DEFAULT NULL,
  `plan_id` int(11) DEFAULT NULL,
  `invoice_id` int(11) DEFAULT NULL,
  `subscriber_name` varchar(255) DEFAULT NULL,
  `account_number` varchar(64) DEFAULT NULL,
  `plan_name` varchar(255) DEFAULT NULL,
  `result_status` enum('CREATED','SKIPPED','FAILED') NOT NULL DEFAULT 'SKIPPED',
  `reason` varchar(255) DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `billing_period_start` date DEFAULT NULL,
  `billing_period_end` date DEFAULT NULL,
  `next_due_date` date DEFAULT NULL,
  `payload_json` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_billing_run_id` (`billing_run_id`),
  KEY `idx_service_id` (`service_id`),
  KEY `idx_invoice_id` (`invoice_id`),
  KEY `idx_result_status` (`result_status`),
  KEY `fk_billing_run_item_plan` (`plan_id`),
  KEY `fk_billing_run_item_subscriber` (`subscriber_id`),
  CONSTRAINT `fk_billing_run_item_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_billing_run_item_plan` FOREIGN KEY (`plan_id`) REFERENCES `plans` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_billing_run_item_service` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_billing_run_item_subscriber` FOREIGN KEY (`subscriber_id`) REFERENCES `subscribers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_billing_run_items_run` FOREIGN KEY (`billing_run_id`) REFERENCES `billing_runs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `billing_runs`
--

DROP TABLE IF EXISTS `billing_runs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `billing_runs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_no` varchar(40) NOT NULL,
  `run_type` enum('MANUAL','CRON','SYSTEM') NOT NULL DEFAULT 'MANUAL',
  `as_of_date` date NOT NULL,
  `checked_count` int(11) NOT NULL DEFAULT 0,
  `created_count` int(11) NOT NULL DEFAULT 0,
  `skipped_count` int(11) NOT NULL DEFAULT 0,
  `failed_count` int(11) NOT NULL DEFAULT 0,
  `status` enum('SUCCESS','PARTIAL','FAILED') NOT NULL DEFAULT 'SUCCESS',
  `message` varchar(255) DEFAULT NULL,
  `triggered_by` int(11) DEFAULT NULL,
  `started_at` datetime NOT NULL,
  `completed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `run_no` (`run_no`),
  KEY `idx_as_of_date` (`as_of_date`),
  KEY `idx_run_type` (`run_type`),
  KEY `idx_status` (`status`),
  KEY `idx_triggered_by` (`triggered_by`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `billing_settings`
--

DROP TABLE IF EXISTS `billing_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `billing_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_billing_settings_key` (`setting_key`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bng_accel_deployments`
--

DROP TABLE IF EXISTS `bng_accel_deployments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `bng_accel_deployments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) NOT NULL,
  `deployment_type` enum('STAGE','ACTIVATE','ROLLBACK','BOOT_RECONCILE') NOT NULL,
  `status` enum('PENDING','SUCCESS','FAILED') NOT NULL DEFAULT 'PENDING',
  `config_hash` char(64) NOT NULL,
  `message` text DEFAULT NULL,
  `performed_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_bng_accel_deployments_profile` (`profile_id`,`created_at`),
  KEY `fk_bng_accel_deployment_user` (`performed_by`),
  CONSTRAINT `fk_bng_accel_deployment_profile` FOREIGN KEY (`profile_id`) REFERENCES `bng_accel_profiles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bng_accel_deployment_user` FOREIGN KEY (`performed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bng_accel_profiles`
--

DROP TABLE IF EXISTS `bng_accel_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `bng_accel_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_name` varchar(100) NOT NULL DEFAULT 'Default BNG',
  `config_json` longtext NOT NULL,
  `radius_secret` text DEFAULT NULL,
  `dae_secret` text DEFAULT NULL,
  `rendered_config` longtext NOT NULL,
  `config_hash` char(64) NOT NULL,
  `status` enum('DRAFT','STAGED','ACTIVE','FAILED') NOT NULL DEFAULT 'DRAFT',
  `restart_required` tinyint(1) NOT NULL DEFAULT 1,
  `staged_at` datetime DEFAULT NULL,
  `staged_by` int(11) DEFAULT NULL,
  `activated_at` datetime DEFAULT NULL,
  `activated_by` int(11) DEFAULT NULL,
  `last_error` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `last_validated_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bng_accel_profile_name` (`profile_name`),
  KEY `fk_bng_accel_staged_by` (`staged_by`),
  KEY `fk_bng_accel_activated_by` (`activated_by`),
  KEY `fk_bng_accel_created_by` (`created_by`),
  KEY `fk_bng_accel_updated_by` (`updated_by`),
  CONSTRAINT `fk_bng_accel_activated_by` FOREIGN KEY (`activated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_bng_accel_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_bng_accel_staged_by` FOREIGN KEY (`staged_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_bng_accel_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bng_settings`
--

DROP TABLE IF EXISTS `bng_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `bng_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `host` varchar(255) NOT NULL,
  `port` int(11) NOT NULL DEFAULT 22,
  `username` varchar(100) NOT NULL,
  `auth_type` varchar(20) NOT NULL DEFAULT 'PASSWORD',
  `password` varchar(255) DEFAULT NULL,
  `known_host_key` text DEFAULT NULL,
  `host_key_fingerprint` varchar(128) DEFAULT NULL,
  `ssh_key_path` varchar(255) DEFAULT NULL,
  `preferred_interface` varchar(64) DEFAULT NULL,
  `bng_parent_interface` varchar(64) DEFAULT NULL,
  `auto_create_svlan_interface` tinyint(1) NOT NULL DEFAULT 1,
  `vlan_mode` varchar(20) NOT NULL DEFAULT 'QINQ',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bng_vlan_interfaces`
--

DROP TABLE IF EXISTS `bng_vlan_interfaces`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `bng_vlan_interfaces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vlan_id` int(11) NOT NULL,
  `interface` varchar(64) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'UP',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `box_splitters`
--

DROP TABLE IF EXISTS `box_splitters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `box_splitters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `legacy_table` varchar(32) DEFAULT NULL,
  `legacy_id` int(11) DEFAULT NULL,
  `box_id` int(11) NOT NULL,
  `splitter_ratio` int(11) NOT NULL,
  `splitter_model` varchar(128) DEFAULT NULL,
  `splitter_role` enum('PRIMARY') NOT NULL DEFAULT 'PRIMARY',
  `status` enum('ACTIVE','INACTIVE','FAULTY') NOT NULL DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_box_id` (`box_id`),
  KEY `idx_legacy_ref` (`legacy_table`,`legacy_id`),
  CONSTRAINT `fk_box_splitters_box` FOREIGN KEY (`box_id`) REFERENCES `network_boxes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `box_uplink_connections`
--

DROP TABLE IF EXISTS `box_uplink_connections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `box_uplink_connections` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `box_id` int(11) NOT NULL,
  `feed_mode` enum('DIRECT_FROM_LCP','CASCADE_FROM_NAP','FIBER') NOT NULL,
  `source_box_id` int(11) DEFAULT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `fiber_core_id` int(11) DEFAULT NULL,
  `source_port_id` int(11) DEFAULT NULL,
  `source_cable_id` int(11) DEFAULT NULL,
  `source_fiber_core` int(11) DEFAULT NULL,
  `splice_point` varchar(128) DEFAULT NULL,
  `splice_note` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `connected_at` timestamp NULL DEFAULT NULL,
  `disconnected_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_one_active_uplink` (`box_id`,`is_active`),
  UNIQUE KEY `uq_active_source_port` (`source_port_id`,`is_active`),
  KEY `idx_feed_mode` (`feed_mode`),
  KEY `idx_source_box` (`source_box_id`),
  KEY `idx_source_port` (`source_port_id`),
  KEY `fk_box_uplink_connections_olt_port` (`olt_port_id`),
  KEY `fk_box_uplink_connections_fiber_core` (`fiber_core_id`),
  CONSTRAINT `fk_box_uplink_connections_box` FOREIGN KEY (`box_id`) REFERENCES `network_boxes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_box_uplink_connections_fiber_core` FOREIGN KEY (`fiber_core_id`) REFERENCES `fiber_cores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_box_uplink_connections_olt_port` FOREIGN KEY (`olt_port_id`) REFERENCES `olt_ports` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_box_uplink_connections_source_box` FOREIGN KEY (`source_box_id`) REFERENCES `network_boxes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_box_uplink_connections_source_port` FOREIGN KEY (`source_port_id`) REFERENCES `splitter_output_ports` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `branding`
--

DROP TABLE IF EXISTS `branding`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `branding` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `company_name` varchar(128) DEFAULT NULL,
  `business_name` varchar(128) DEFAULT NULL,
  `portal_title` varchar(128) DEFAULT NULL,
  `company_address` text DEFAULT NULL,
  `logo_path` varchar(255) DEFAULT NULL,
  `support_email` varchar(128) DEFAULT NULL,
  `support_phone` varchar(64) DEFAULT NULL,
  `tin` varchar(64) DEFAULT NULL,
  `website` varchar(128) DEFAULT NULL,
  `primary_color` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cgnat_assignments`
--

DROP TABLE IF EXISTS `cgnat_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cgnat_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) NOT NULL,
  `ip_address` varchar(64) DEFAULT NULL,
  `pool_id` int(11) DEFAULT NULL,
  `assigned_at` datetime DEFAULT NULL,
  `released_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `service_id` (`service_id`,`ip_address`),
  KEY `pool_id` (`pool_id`),
  CONSTRAINT `cgnat_assignments_ibfk_1` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`),
  CONSTRAINT `cgnat_assignments_ibfk_2` FOREIGN KEY (`pool_id`) REFERENCES `cgnat_pools` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cgnat_deployments`
--

DROP TABLE IF EXISTS `cgnat_deployments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cgnat_deployments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pool_id` int(11) NOT NULL,
  `target_type` enum('ACCEL','FRR') NOT NULL,
  `status` enum('PENDING','SUCCESS','FAILED') NOT NULL DEFAULT 'PENDING',
  `rendered_config` longtext DEFAULT NULL,
  `result_message` text DEFAULT NULL,
  `applied_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_ip_deployments_pool` (`pool_id`),
  KEY `idx_ip_deployments_target` (`target_type`),
  KEY `idx_ip_deployments_status` (`status`),
  CONSTRAINT `fk_ip_deployments_pool` FOREIGN KEY (`pool_id`) REFERENCES `cgnat_pools` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cgnat_pools`
--

DROP TABLE IF EXISTS `cgnat_pools`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cgnat_pools` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pool_name` varchar(64) DEFAULT NULL,
  `network` varchar(64) DEFAULT NULL,
  `gateway` varchar(64) DEFAULT NULL,
  `range_start` varchar(64) DEFAULT NULL,
  `range_end` varchar(64) DEFAULT NULL,
  `accel_pool_name` varchar(64) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE','DRAFT') NOT NULL DEFAULT 'DRAFT',
  `remarks` text DEFAULT NULL,
  `type` enum('CGNAT','PUBLIC','MANAGEMENT') DEFAULT 'CGNAT',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `pool_name` (`pool_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cgnat_settings`
--

DROP TABLE IF EXISTS `cgnat_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cgnat_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `enabled` tinyint(1) DEFAULT 0,
  `inside_network` varchar(64) NOT NULL,
  `bng_interface` varchar(32) DEFAULT NULL,
  `public_start_ip` varchar(64) NOT NULL,
  `public_end_ip` varchar(64) NOT NULL,
  `egress_interface` varchar(32) DEFAULT NULL,
  `applied_state_json` longtext DEFAULT NULL,
  `applied_at` datetime DEFAULT NULL,
  `router_next_hop` varchar(64) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fiber_cables`
--

DROP TABLE IF EXISTS `fiber_cables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fiber_cables` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cable_code` varchar(64) NOT NULL,
  `cable_name` varchar(128) NOT NULL,
  `cable_type` enum('FEEDER','DISTRIBUTION','DROP') NOT NULL,
  `fiber_core_count` int(11) NOT NULL,
  `source_location` varchar(255) DEFAULT NULL,
  `destination_location` varchar(255) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE','FAULTY') NOT NULL DEFAULT 'ACTIVE',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `cable_code` (`cable_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fiber_cores`
--

DROP TABLE IF EXISTS `fiber_cores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fiber_cores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cable_id` int(11) NOT NULL,
  `core_number` int(11) NOT NULL,
  `status` enum('AVAILABLE','USED','RESERVED','FAULTY') NOT NULL DEFAULT 'AVAILABLE',
  `assigned_box_id` int(11) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cable_core` (`cable_id`,`core_number`),
  KEY `idx_assigned_box` (`assigned_box_id`),
  CONSTRAINT `fk_fiber_cores_cable` FOREIGN KEY (`cable_id`) REFERENCES `fiber_cables` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `infrastructure_monitoring_delivery_queue`
--

DROP TABLE IF EXISTS `infrastructure_monitoring_delivery_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `infrastructure_monitoring_delivery_queue` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `snapshot_id` bigint(20) unsigned NOT NULL,
  `payload_hash` char(64) NOT NULL,
  `status` enum('PENDING','DELIVERED','FAILED') NOT NULL DEFAULT 'PENDING',
  `attempts` int(10) unsigned NOT NULL DEFAULT 0,
  `next_attempt_at` datetime NOT NULL DEFAULT current_timestamp(),
  `last_error_code` varchar(64) DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_infra_delivery_snapshot` (`snapshot_id`),
  KEY `idx_infra_delivery_due` (`status`,`next_attempt_at`),
  CONSTRAINT `fk_infra_delivery_snapshot` FOREIGN KEY (`snapshot_id`) REFERENCES `infrastructure_monitoring_snapshots` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5064 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `infrastructure_monitoring_events`
--

DROP TABLE IF EXISTS `infrastructure_monitoring_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `infrastructure_monitoring_events` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `instance_id` varchar(64) NOT NULL,
  `previous_status` varchar(16) DEFAULT NULL,
  `current_status` varchar(16) NOT NULL,
  `started_at` datetime NOT NULL,
  `recovered_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_infra_events_instance_time` (`instance_id`,`started_at`),
  KEY `idx_infra_events_open` (`instance_id`,`recovered_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `infrastructure_monitoring_snapshots`
--

DROP TABLE IF EXISTS `infrastructure_monitoring_snapshots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `infrastructure_monitoring_snapshots` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `instance_id` varchar(64) NOT NULL,
  `overall_status` varchar(16) NOT NULL,
  `payload_json` longtext NOT NULL,
  `collected_at` datetime NOT NULL,
  `collection_duration_ms` int(10) unsigned NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_infra_monitoring_instance_time` (`instance_id`,`collected_at`),
  KEY `idx_infra_monitoring_status_time` (`overall_status`,`collected_at`)
) ENGINE=InnoDB AUTO_INCREMENT=5880 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invoice_items`
--

DROP TABLE IF EXISTS `invoice_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoice_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `invoice_id` int(11) NOT NULL,
  `item_type` enum('PLAN','INSTALLATION','ADJUSTMENT','DISCOUNT','PENALTY','OTHER') NOT NULL DEFAULT 'PLAN',
  `description` varchar(255) NOT NULL,
  `quantity` decimal(10,2) NOT NULL DEFAULT 1.00,
  `unit_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `line_total` decimal(10,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_invoice_items_invoice_id` (`invoice_id`),
  CONSTRAINT `fk_invoice_items_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `invoice_no` varchar(32) DEFAULT NULL,
  `service_id` int(11) DEFAULT NULL,
  `subscriber_id` int(11) DEFAULT NULL,
  `plan_id` int(11) DEFAULT NULL,
  `billing_period_start` date DEFAULT NULL,
  `billing_period_end` date DEFAULT NULL,
  `issue_date` date DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `discount_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tax_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `paid_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `balance_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `due_date` date DEFAULT NULL,
  `status` enum('DRAFT','UNPAID','PARTIAL','PAID','OVERDUE','CANCELLED') NOT NULL DEFAULT 'UNPAID',
  `notes` text DEFAULT NULL,
  `internal_notes` text DEFAULT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  `cancelled_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_invoices_invoice_no` (`invoice_no`),
  UNIQUE KEY `uq_invoice_service_period` (`service_id`,`billing_period_start`,`billing_period_end`),
  KEY `idx_invoices_user_status` (`status`),
  KEY `idx_invoice_due` (`due_date`),
  KEY `idx_invoice_status` (`status`),
  KEY `idx_invoices_subscriber_id` (`subscriber_id`),
  KEY `idx_invoices_service_id` (`service_id`),
  KEY `idx_invoices_plan_id` (`plan_id`),
  KEY `idx_invoices_due_status` (`due_date`,`status`),
  CONSTRAINT `fk_invoice_service` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`),
  CONSTRAINT `fk_invoices_plan` FOREIGN KEY (`plan_id`) REFERENCES `plans` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_invoices_subscriber` FOREIGN KEY (`subscriber_id`) REFERENCES `subscribers` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lcp_boxes`
--

DROP TABLE IF EXISTS `lcp_boxes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `lcp_boxes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lcp_name` varchar(64) NOT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `splitter_ports` int(11) NOT NULL,
  `location` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `maintenance_mode` tinyint(1) DEFAULT 0,
  `maintenance_reason` varchar(255) DEFAULT NULL,
  `maintenance_started_at` datetime DEFAULT NULL,
  `maintenance_resolution` text DEFAULT NULL,
  `maintenance_ended_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_lcp_boxes_olt_port` (`olt_port_id`),
  CONSTRAINT `fk_lcp_boxes_olt_port` FOREIGN KEY (`olt_port_id`) REFERENCES `olt_ports` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lcp_ports`
--

DROP TABLE IF EXISTS `lcp_ports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `lcp_ports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lcp_id` int(11) NOT NULL,
  `port_number` int(11) NOT NULL,
  `status` enum('FREE','USED') DEFAULT 'FREE',
  `nap_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_lcp_port` (`lcp_id`,`port_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `login_attempts`
--

DROP TABLE IF EXISTS `login_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `login_attempts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `attempts` int(11) DEFAULT 1,
  `last_attempt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `locked_until` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nap_boxes`
--

DROP TABLE IF EXISTS `nap_boxes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `nap_boxes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lcp_id` int(11) DEFAULT NULL,
  `olt_id` int(11) DEFAULT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `nap_name` varchar(64) DEFAULT NULL,
  `parent_type` enum('LCP','NAP') NOT NULL DEFAULT 'LCP',
  `parent_lcp_id` int(11) DEFAULT NULL,
  `parent_nap_id` int(11) DEFAULT NULL,
  `parent_port_id` int(11) DEFAULT NULL,
  `location` text DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` varchar(20) DEFAULT 'active',
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `maintenance_mode` tinyint(1) DEFAULT 0,
  `maintenance_reason` varchar(255) DEFAULT NULL,
  `maintenance_started_at` datetime DEFAULT NULL,
  `maintenance_resolution` text DEFAULT NULL,
  `maintenance_ended_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nap_name` (`nap_name`),
  UNIQUE KEY `unique_nap_per_lcp` (`lcp_id`,`nap_name`),
  KEY `idx_nap_parent_lcp` (`parent_lcp_id`),
  KEY `idx_nap_parent_nap` (`parent_nap_id`),
  KEY `idx_nap_parent_port` (`parent_port_id`),
  KEY `idx_nap_parent_type` (`parent_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nap_ports`
--

DROP TABLE IF EXISTS `nap_ports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `nap_ports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nap_splitter_id` int(11) NOT NULL,
  `port_number` int(11) NOT NULL,
  `status` enum('AVAILABLE','RESERVED','USED','FAULTY') DEFAULT 'AVAILABLE',
  `service_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `installed_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `reserved_label` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_splitter_port` (`nap_splitter_id`,`port_number`),
  KEY `service_id` (`service_id`),
  KEY `idx_nap_available` (`nap_splitter_id`,`status`),
  CONSTRAINT `fk_nap_ports_splitter` FOREIGN KEY (`nap_splitter_id`) REFERENCES `nap_splitters` (`id`),
  CONSTRAINT `nap_ports_ibfk_1` FOREIGN KEY (`nap_splitter_id`) REFERENCES `nap_splitters` (`id`),
  CONSTRAINT `nap_ports_ibfk_2` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nap_splitters`
--

DROP TABLE IF EXISTS `nap_splitters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `nap_splitters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nap_id` int(11) NOT NULL,
  `splitter_label` varchar(32) DEFAULT NULL,
  `splitter_ports` int(11) DEFAULT NULL,
  `splitter_ratio` varchar(16) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `nap_id` (`nap_id`),
  CONSTRAINT `nap_splitters_ibfk_1` FOREIGN KEY (`nap_id`) REFERENCES `nap_boxes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `network_boxes`
--

DROP TABLE IF EXISTS `network_boxes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `network_boxes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `legacy_table` varchar(32) DEFAULT NULL,
  `legacy_id` int(11) DEFAULT NULL,
  `box_type` enum('LCP','NAP') NOT NULL,
  `box_code` varchar(64) NOT NULL,
  `box_name` varchar(128) NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `pole_code` varchar(64) DEFAULT NULL,
  `olt_id` int(11) DEFAULT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `parent_odf_id` int(11) DEFAULT NULL,
  `parent_odf_port_id` int(11) DEFAULT NULL,
  `input_port_number` int(11) DEFAULT NULL,
  `ingress_port_id` int(11) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE','MAINTENANCE','FAULTY') NOT NULL DEFAULT 'ACTIVE',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `box_code` (`box_code`),
  UNIQUE KEY `uniq_lcp_parent_odf_port` (`box_type`,`parent_odf_port_id`),
  KEY `idx_box_type` (`box_type`),
  KEY `idx_status` (`status`),
  KEY `idx_legacy_ref` (`legacy_table`,`legacy_id`),
  KEY `fk_network_boxes_olt` (`olt_id`),
  KEY `fk_network_boxes_olt_port` (`olt_port_id`),
  CONSTRAINT `fk_network_boxes_olt` FOREIGN KEY (`olt_id`) REFERENCES `olt_devices` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_network_boxes_olt_port` FOREIGN KEY (`olt_port_id`) REFERENCES `olt_ports` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `network_design_build_items`
--

DROP TABLE IF EXISTS `network_design_build_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `network_design_build_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `build_id` int(11) NOT NULL,
  `item_type` enum('LCP','NAP','BOX_SPLITTER','SPLITTER_PORT','UPLINK','FIBER_CABLE','FIBER_CORE') NOT NULL,
  `item_id` int(11) NOT NULL,
  `item_label` varchar(255) DEFAULT NULL,
  `sequence_no` int(11) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_network_design_build_items_build` (`build_id`),
  CONSTRAINT `fk_network_design_build_items_build` FOREIGN KEY (`build_id`) REFERENCES `network_design_builds` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `network_design_builds`
--

DROP TABLE IF EXISTS `network_design_builds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `network_design_builds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `build_code` varchar(64) NOT NULL,
  `profile_id` int(11) NOT NULL,
  `olt_id` int(11) NOT NULL,
  `olt_port_id` int(11) NOT NULL,
  `feeder_cable_id` int(11) DEFAULT NULL,
  `feeder_fiber_core_id` int(11) DEFAULT NULL,
  `lcp_box_id` int(11) DEFAULT NULL,
  `build_name` varchar(128) NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `build_status` enum('PLANNED','GENERATED','DEPLOYED','CANCELLED') NOT NULL DEFAULT 'PLANNED',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `build_code` (`build_code`),
  KEY `fk_network_design_builds_profile` (`profile_id`),
  KEY `fk_network_design_builds_olt` (`olt_id`),
  KEY `fk_network_design_builds_olt_port` (`olt_port_id`),
  KEY `fk_network_design_builds_feeder_cable` (`feeder_cable_id`),
  KEY `fk_network_design_builds_feeder_core` (`feeder_fiber_core_id`),
  KEY `fk_network_design_builds_lcp_box` (`lcp_box_id`),
  CONSTRAINT `fk_network_design_builds_feeder_cable` FOREIGN KEY (`feeder_cable_id`) REFERENCES `fiber_cables` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_network_design_builds_feeder_core` FOREIGN KEY (`feeder_fiber_core_id`) REFERENCES `fiber_cores` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_network_design_builds_lcp_box` FOREIGN KEY (`lcp_box_id`) REFERENCES `network_boxes` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_network_design_builds_olt` FOREIGN KEY (`olt_id`) REFERENCES `olt_devices` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_network_design_builds_olt_port` FOREIGN KEY (`olt_port_id`) REFERENCES `olt_ports` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_network_design_builds_profile` FOREIGN KEY (`profile_id`) REFERENCES `network_design_profiles` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `network_design_profile_nap_rules`
--

DROP TABLE IF EXISTS `network_design_profile_nap_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `network_design_profile_nap_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) NOT NULL,
  `nap_level` int(11) NOT NULL DEFAULT 1,
  `nap_count` int(11) NOT NULL DEFAULT 1,
  `splitter_ratio` int(11) NOT NULL DEFAULT 8,
  `uplink_mode` enum('FROM_LCP_SPLITTER','FROM_PARENT_NAP_FIBER','FROM_LCP_FIBER') NOT NULL DEFAULT 'FROM_LCP_SPLITTER',
  `require_fiber_core` tinyint(1) NOT NULL DEFAULT 0,
  `allow_same_pole_grouping` tinyint(1) NOT NULL DEFAULT 0,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_design_profile_nap_rules_profile` (`profile_id`),
  CONSTRAINT `fk_design_profile_nap_rules_profile` FOREIGN KEY (`profile_id`) REFERENCES `network_design_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `network_design_profiles`
--

DROP TABLE IF EXISTS `network_design_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `network_design_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_code` varchar(64) NOT NULL,
  `profile_name` varchar(128) NOT NULL,
  `description` text DEFAULT NULL,
  `topology_type` enum('DISTRIBUTED_SPLIT','CENTRALIZED_SPLIT','FIBER_ONLY_DISTRIBUTION','CASCADE_NAP') NOT NULL DEFAULT 'DISTRIBUTED_SPLIT',
  `feeder_mode` enum('OLT_TO_LCP_FIBER') NOT NULL DEFAULT 'OLT_TO_LCP_FIBER',
  `lcp_splitter_ratio` int(11) NOT NULL DEFAULT 8,
  `nap_splitter_ratio` int(11) NOT NULL DEFAULT 8,
  `default_nap_count` int(11) NOT NULL DEFAULT 4,
  `max_nap_count` int(11) NOT NULL DEFAULT 8,
  `allow_nap_to_nap_fiber` tinyint(1) NOT NULL DEFAULT 1,
  `allow_nap_to_nap_splitter` tinyint(1) NOT NULL DEFAULT 0,
  `require_feeder_fiber_core` tinyint(1) NOT NULL DEFAULT 1,
  `require_distribution_fiber_core` tinyint(1) NOT NULL DEFAULT 0,
  `status` enum('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `profile_code` (`profile_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `network_links`
--

DROP TABLE IF EXISTS `network_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `network_links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `link_type` enum('FEEDER','DISTRIBUTION','DROP') NOT NULL,
  `source_node_id` int(11) NOT NULL,
  `target_node_id` int(11) NOT NULL,
  `cable_id` int(11) DEFAULT NULL,
  `fiber_core_id` int(11) DEFAULT NULL,
  `source_port_id` int(11) DEFAULT NULL,
  `source_port_type` enum('ODF_PORT','OLT_PORT','SPLITTER_PORT','GENERIC_NODE_PORT') DEFAULT NULL,
  `target_port_id` int(11) DEFAULT NULL,
  `target_port_type` enum('ODF_PORT','OLT_PORT','SPLITTER_PORT','GENERIC_NODE_PORT') DEFAULT NULL,
  `connection_mode` enum('DIRECT_FROM_ODF','DIRECT_FROM_LCP','CASCADE_FROM_NAP') DEFAULT NULL,
  `splice_point` varchar(128) DEFAULT NULL,
  `splice_note` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_network_links_cable` (`cable_id`),
  KEY `fk_network_links_fiber_core` (`fiber_core_id`),
  KEY `idx_network_links_source` (`source_node_id`),
  KEY `idx_network_links_target` (`target_node_id`),
  KEY `idx_network_links_type` (`link_type`),
  KEY `idx_network_links_active` (`is_active`),
  CONSTRAINT `fk_network_links_cable` FOREIGN KEY (`cable_id`) REFERENCES `fiber_cables` (`id`),
  CONSTRAINT `fk_network_links_fiber_core` FOREIGN KEY (`fiber_core_id`) REFERENCES `fiber_cores` (`id`),
  CONSTRAINT `fk_network_links_source_node` FOREIGN KEY (`source_node_id`) REFERENCES `network_nodes` (`id`),
  CONSTRAINT `fk_network_links_target_node` FOREIGN KEY (`target_node_id`) REFERENCES `network_nodes` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `network_nodes`
--

DROP TABLE IF EXISTS `network_nodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `network_nodes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `node_type` enum('ODF','LCP','NAP') NOT NULL,
  `reference_table` varchar(64) DEFAULT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `node_code` varchar(64) NOT NULL,
  `node_name` varchar(128) NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE','MAINTENANCE','FAULTY') NOT NULL DEFAULT 'ACTIVE',
  `remarks` text DEFAULT NULL,
  `planner_x` decimal(12,2) DEFAULT NULL,
  `planner_y` decimal(12,2) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `node_code` (`node_code`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `network_objects`
--

DROP TABLE IF EXISTS `network_objects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `network_objects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `object_type` enum('OLT','ODF','FDT','NAP','ONT') DEFAULT NULL,
  `object_name` varchar(128) NOT NULL,
  `object_code` varchar(64) DEFAULT NULL,
  `reference_table` varchar(64) DEFAULT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `olt_device_id` int(11) DEFAULT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE','MAINTENANCE','FAULTY') NOT NULL DEFAULT 'ACTIVE',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `object_code` (`object_code`),
  KEY `idx_network_objects_type` (`object_type`),
  KEY `idx_network_objects_ref` (`reference_table`,`reference_id`),
  KEY `idx_network_objects_olt` (`olt_device_id`),
  KEY `idx_network_objects_olt_port` (`olt_port_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `network_vlans`
--

DROP TABLE IF EXISTS `network_vlans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `network_vlans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `olt_id` int(11) NOT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `parent_svlan_id` int(11) DEFAULT NULL,
  `vlan_id` int(11) DEFAULT NULL,
  `vlan_type` enum('C_VLAN','S_VLAN') NOT NULL DEFAULT 'C_VLAN',
  `name` varchar(64) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `deployment_status` varchar(32) NOT NULL DEFAULT 'PENDING',
  `deployed_at` datetime DEFAULT NULL,
  `deployment_output` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_network_vlans_olt_vlan` (`olt_id`,`vlan_id`),
  UNIQUE KEY `uq_network_vlans_olt_port` (`olt_id`,`olt_port_id`),
  KEY `idx_olt_id` (`olt_id`),
  KEY `idx_network_vlans_olt_port_id` (`olt_port_id`),
  KEY `idx_network_vlans_parent_svlan` (`parent_svlan_id`),
  CONSTRAINT `fk_network_vlans_parent_svlan` FOREIGN KEY (`parent_svlan_id`) REFERENCES `network_vlans` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `odf_nodes`
--

DROP TABLE IF EXISTS `odf_nodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `odf_nodes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `odf_name` varchar(128) NOT NULL,
  `node_code` varchar(64) NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `olt_id` int(11) DEFAULT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `input_port_number` int(11) DEFAULT NULL,
  `uplink_odf_port_id` int(11) DEFAULT NULL,
  `port_count` int(11) NOT NULL DEFAULT 24,
  `port_naming_mode` enum('NUMERIC','CUSTOM') NOT NULL DEFAULT 'NUMERIC',
  `remarks` text DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE','MAINTENANCE','FAULTY') NOT NULL DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `node_code` (`node_code`),
  KEY `fk_odf_nodes_olt` (`olt_id`),
  CONSTRAINT `fk_odf_nodes_olt` FOREIGN KEY (`olt_id`) REFERENCES `olt_devices` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `odf_ports`
--

DROP TABLE IF EXISTS `odf_ports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `odf_ports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `odf_id` int(11) NOT NULL,
  `port_number` int(11) NOT NULL,
  `port_label` varchar(64) DEFAULT NULL,
  `port_side` enum('LINE','DIST','CLIENT','GENERIC') NOT NULL DEFAULT 'GENERIC',
  `port_role` enum('IN','OUT','PATCH','SPLICE','RESERVE') NOT NULL DEFAULT 'PATCH',
  `status` enum('AVAILABLE','USED','RESERVED','FAULTY') NOT NULL DEFAULT 'AVAILABLE',
  `connected_entity_type` enum('NONE','OLT_PORT','FIBER_CABLE','NETWORK_NODE','LCP','NAP') NOT NULL DEFAULT 'NONE',
  `connected_entity_id` int(11) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_odf_port` (`odf_id`,`port_number`),
  CONSTRAINT `fk_odf_ports_odf` FOREIGN KEY (`odf_id`) REFERENCES `odf_nodes` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_dba_profiles`
--

DROP TABLE IF EXISTS `olt_dba_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_dba_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `olt_id` int(11) DEFAULT NULL,
  `profile_id` int(11) NOT NULL,
  `profile_name` varchar(100) NOT NULL,
  `dba_type` varchar(50) NOT NULL,
  `max_bandwidth` int(11) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_devices`
--

DROP TABLE IF EXISTS `olt_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `ip_address` varchar(64) DEFAULT NULL,
  `username` varchar(64) DEFAULT NULL,
  `password` text NOT NULL,
  `vendor` varchar(32) DEFAULT NULL,
  `enable_home_gateway_omci` tinyint(1) NOT NULL DEFAULT 1,
  `auto_detect_omci_support` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `omci_mode` enum('omci','default') DEFAULT 'default',
  `omci_last_applied_at` datetime DEFAULT NULL,
  `omci_last_status` tinyint(1) DEFAULT 0,
  `omci_last_output` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_mgmt_vlans`
--

DROP TABLE IF EXISTS `olt_mgmt_vlans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_mgmt_vlans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `olt_id` int(11) NOT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `mgmt_vlan` int(11) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_olt_mgmt_vlan_olt_vlan` (`olt_id`,`mgmt_vlan`),
  KEY `idx_olt_mgmt_vlans_olt_port` (`olt_port_id`),
  CONSTRAINT `fk_olt_mgmt_vlans_olt_id` FOREIGN KEY (`olt_id`) REFERENCES `olt_devices` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_olt_mgmt_vlans_olt_port` FOREIGN KEY (`olt_port_id`) REFERENCES `olt_ports` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_ont_line_profiles`
--

DROP TABLE IF EXISTS `olt_ont_line_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_ont_line_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `olt_id` int(11) DEFAULT NULL,
  `profile_id` int(11) NOT NULL,
  `profile_name` varchar(100) NOT NULL,
  `customer_cvlan` int(11) NOT NULL,
  `management_vlan` int(11) NOT NULL DEFAULT 25,
  `omcc_encrypt` tinyint(1) NOT NULL DEFAULT 1,
  `tr069_management_enable` tinyint(1) NOT NULL DEFAULT 1,
  `tr069_ip_index` int(11) NOT NULL DEFAULT 1,
  `tcont_id` int(11) NOT NULL DEFAULT 1,
  `dba_profile_id` int(11) NOT NULL DEFAULT 20,
  `gem_subscriber_id` int(11) NOT NULL DEFAULT 1,
  `gem_management_id` int(11) NOT NULL DEFAULT 2,
  `gem_subscriber_encrypt` tinyint(1) NOT NULL DEFAULT 1,
  `gem_management_encrypt` tinyint(1) NOT NULL DEFAULT 1,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_profile_id` (`profile_id`),
  UNIQUE KEY `uq_profile_name` (`profile_name`),
  UNIQUE KEY `uq_customer_cvlan` (`customer_cvlan`),
  KEY `idx_olt_id` (`olt_id`),
  KEY `idx_cvlan` (`customer_cvlan`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_port_svlan_members`
--

DROP TABLE IF EXISTS `olt_port_svlan_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_port_svlan_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `olt_port_id` int(11) NOT NULL,
  `svlan` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_olt_port_svlan_member` (`olt_port_id`,`svlan`),
  CONSTRAINT `fk_olt_port_svlan_members_port` FOREIGN KEY (`olt_port_id`) REFERENCES `olt_ports` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_port_vlan_bindings`
--

DROP TABLE IF EXISTS `olt_port_vlan_bindings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_port_vlan_bindings` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `olt_id` bigint(20) unsigned NOT NULL,
  `olt_port_id` bigint(20) unsigned NOT NULL,
  `network_vlan_id` int(11) NOT NULL,
  `vlan_id` bigint(20) unsigned NOT NULL,
  `vlan_type` enum('SERVICE','MGMT') NOT NULL,
  `frame` int(11) NOT NULL,
  `slot` int(11) NOT NULL,
  `control_board_port` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_port_vlan_type` (`olt_port_id`,`vlan_type`,`vlan_id`),
  KEY `idx_olt` (`olt_id`),
  KEY `idx_port` (`olt_port_id`),
  KEY `idx_vlan` (`vlan_id`),
  KEY `idx_opvb_network_vlan_id` (`network_vlan_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_ports`
--

DROP TABLE IF EXISTS `olt_ports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_ports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `olt_id` int(11) NOT NULL,
  `board_name` varchar(64) DEFAULT NULL,
  `board_status` varchar(64) DEFAULT NULL,
  `board_type` varchar(32) DEFAULT NULL,
  `port_type` varchar(32) DEFAULT NULL,
  `link_status` varchar(32) DEFAULT NULL,
  `optic_status` varchar(32) DEFAULT NULL,
  `speed` varchar(32) DEFAULT NULL,
  `duplex` varchar(32) DEFAULT NULL,
  `active_state` varchar(32) DEFAULT NULL,
  `ont_count` int(11) DEFAULT NULL,
  `ont_online` int(11) DEFAULT NULL,
  `frame` int(11) DEFAULT NULL,
  `slot` int(11) DEFAULT NULL,
  `port` int(11) DEFAULT NULL,
  `svlan` int(11) DEFAULT NULL,
  `description` varchar(128) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_olt_physical_port` (`olt_id`,`frame`,`slot`,`port`),
  CONSTRAINT `olt_ports_ibfk_1` FOREIGN KEY (`olt_id`) REFERENCES `olt_devices` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_srv_profiles`
--

DROP TABLE IF EXISTS `olt_srv_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_srv_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `olt_id` int(11) DEFAULT NULL,
  `profile_id` int(11) NOT NULL,
  `profile_name` varchar(100) NOT NULL,
  `eth_port_count` int(11) DEFAULT 4,
  `pots_port_count` int(11) DEFAULT 0,
  `catv_enable` tinyint(1) DEFAULT 0,
  `service_mode` varchar(50) DEFAULT 'transparent',
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_tr069_profiles`
--

DROP TABLE IF EXISTS `olt_tr069_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_tr069_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `olt_id` int(11) DEFAULT NULL,
  `profile_id` int(11) NOT NULL,
  `profile_name` varchar(100) NOT NULL,
  `acs_url` text NOT NULL,
  `acs_username` varchar(100) DEFAULT NULL,
  `acs_password` text DEFAULT NULL,
  `periodic_inform_enable` tinyint(1) DEFAULT 1,
  `periodic_inform_interval` int(11) DEFAULT 300,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `olt_wan_profiles`
--

DROP TABLE IF EXISTS `olt_wan_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `olt_wan_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `olt_id` int(11) DEFAULT NULL,
  `profile_id` int(11) NOT NULL,
  `profile_name` varchar(100) NOT NULL,
  `connection_type` enum('PPPOE','DHCP') NOT NULL,
  `nat_enable` tinyint(1) DEFAULT 0,
  `vlan_mode` varchar(50) DEFAULT 'transparent',
  `service_type` varchar(50) DEFAULT 'internet',
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ont_acs`
--

DROP TABLE IF EXISTS `ont_acs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ont_acs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `serial_number` varchar(64) DEFAULT NULL,
  `wan_ip` varchar(64) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `last_seen` datetime DEFAULT NULL,
  `firmware_version` varchar(64) DEFAULT NULL,
  `uptime` varchar(64) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ont_autofind`
--

DROP TABLE IF EXISTS `ont_autofind`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ont_autofind` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `serial_number` varchar(64) DEFAULT NULL,
  `vendor` varchar(32) DEFAULT NULL,
  `vendor_code` varchar(16) DEFAULT NULL,
  `model` varchar(64) DEFAULT NULL,
  `fsp` varchar(32) DEFAULT NULL,
  `frame` int(11) DEFAULT NULL,
  `slot` int(11) DEFAULT NULL,
  `port` int(11) DEFAULT NULL,
  `autofind_time` datetime DEFAULT NULL,
  `status` enum('NEW','PROCESSED') DEFAULT 'NEW',
  `last_seen` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ont_autofind_serial` (`serial_number`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ont_devices`
--

DROP TABLE IF EXISTS `ont_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ont_devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `serial_number` varchar(64) DEFAULT NULL,
  `model` varchar(64) DEFAULT NULL,
  `vendor` varchar(32) DEFAULT NULL,
  `mac_address` varchar(64) DEFAULT NULL,
  `status` enum('UNASSIGNED','ASSIGNED','OFFLINE') DEFAULT 'UNASSIGNED',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `equipment_id` varchar(64) DEFAULT NULL,
  `subscriber_id` int(11) DEFAULT NULL,
  `olt_id` int(11) DEFAULT NULL,
  `frame` int(11) DEFAULT NULL,
  `slot` int(11) DEFAULT NULL,
  `port` int(11) DEFAULT NULL,
  `ont_id` int(11) DEFAULT NULL,
  `last_rx_power_dbm` decimal(8,2) DEFAULT NULL,
  `last_tx_power_dbm` decimal(8,2) DEFAULT NULL,
  `last_olt_rx_ont_power_dbm` decimal(8,2) DEFAULT NULL,
  `last_temperature_c` decimal(8,2) DEFAULT NULL,
  `last_voltage_v` decimal(8,2) DEFAULT NULL,
  `last_laser_bias_current_ma` decimal(8,2) DEFAULT NULL,
  `last_distance_m` int(11) DEFAULT NULL,
  `last_optical_polled_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `serial_number` (`serial_number`),
  KEY `idx_ont_serial` (`serial_number`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payment_allocations`
--

DROP TABLE IF EXISTS `payment_allocations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_allocations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `payment_id` int(11) NOT NULL,
  `invoice_id` int(11) NOT NULL,
  `allocated_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_payment_invoice_allocation` (`payment_id`,`invoice_id`),
  KEY `idx_payment_allocations_payment_id` (`payment_id`),
  KEY `idx_payment_allocations_invoice_id` (`invoice_id`),
  CONSTRAINT `fk_payment_allocations_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_payment_allocations_payment` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payment_gateway_settings`
--

DROP TABLE IF EXISTS `payment_gateway_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_gateway_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `setting_key` (`setting_key`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payment_gateway_transactions`
--

DROP TABLE IF EXISTS `payment_gateway_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_gateway_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `payment_id` int(11) DEFAULT NULL,
  `invoice_id` int(11) DEFAULT NULL,
  `subscriber_id` int(11) DEFAULT NULL,
  `gateway` varchar(32) NOT NULL,
  `gateway_reference` varchar(128) DEFAULT NULL,
  `gateway_payment_url` text DEFAULT NULL,
  `gateway_status` varchar(32) NOT NULL DEFAULT 'PENDING',
  `amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `currency` varchar(8) NOT NULL DEFAULT 'PHP',
  `raw_request` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`raw_request`)),
  `raw_response` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`raw_response`)),
  `raw_webhook` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`raw_webhook`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_gateway_reference` (`gateway`,`gateway_reference`),
  KEY `idx_gateway_reference` (`gateway_reference`),
  KEY `idx_invoice_id` (`invoice_id`),
  KEY `idx_payment_id` (`payment_id`),
  KEY `idx_gateway_status` (`gateway_status`),
  KEY `fk_gateway_transaction_subscriber` (`subscriber_id`),
  CONSTRAINT `fk_gateway_transaction_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`),
  CONSTRAINT `fk_gateway_transaction_payment` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_gateway_transaction_subscriber` FOREIGN KEY (`subscriber_id`) REFERENCES `subscribers` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `payment_no` varchar(32) DEFAULT NULL,
  `invoice_id` int(11) DEFAULT NULL,
  `subscriber_id` int(11) DEFAULT NULL,
  `service_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `payment_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `method` varchar(32) DEFAULT NULL,
  `reference_no` varchar(64) DEFAULT NULL,
  `payment_status` enum('PENDING','POSTED','FAILED','REJECTED','VOIDED','REFUNDED') NOT NULL DEFAULT 'POSTED',
  `remarks` text DEFAULT NULL,
  `proof_file_path` varchar(500) DEFAULT NULL,
  `proof_file_name` varchar(255) DEFAULT NULL,
  `proof_file_type` varchar(100) DEFAULT NULL,
  `submitted_by_user_id` int(11) DEFAULT NULL,
  `reviewed_by_user_id` int(11) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `rejection_reason` varchar(1000) DEFAULT NULL,
  `received_by` int(11) DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `voided_by` int(11) DEFAULT NULL,
  `void_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_payments_payment_no` (`payment_no`),
  KEY `idx_payments_invoice_id` (`invoice_id`),
  KEY `idx_payments_subscriber_id` (`subscriber_id`),
  KEY `idx_payments_service_id` (`service_id`),
  KEY `idx_payments_date_status` (`payment_date`,`payment_status`),
  KEY `fk_payments_submitted_by` (`submitted_by_user_id`),
  KEY `fk_payments_reviewed_by` (`reviewed_by_user_id`),
  KEY `idx_payments_pending_review` (`payment_status`,`submitted_by_user_id`),
  CONSTRAINT `fk_payment_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`),
  CONSTRAINT `fk_payments_reviewed_by` FOREIGN KEY (`reviewed_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_payments_service` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_payments_submitted_by` FOREIGN KEY (`submitted_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_payments_subscriber` FOREIGN KEY (`subscriber_id`) REFERENCES `subscribers` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `permissions`
--

DROP TABLE IF EXISTS `permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `permissions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `permission_key` varchar(120) NOT NULL,
  `module_key` varchar(60) NOT NULL,
  `action_key` varchar(40) NOT NULL,
  `label` varchar(140) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `is_sensitive` tinyint(1) NOT NULL DEFAULT 0,
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_permissions_key` (`permission_key`),
  KEY `idx_permissions_module` (`module_key`,`sort_order`)
) ENGINE=InnoDB AUTO_INCREMENT=276 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `plans`
--

DROP TABLE IF EXISTS `plans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `plans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plan_name` varchar(32) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `plan_type` enum('POSTPAID','PREPAID') NOT NULL DEFAULT 'POSTPAID',
  `validity_days` int(11) NOT NULL DEFAULT 30,
  `speed_down` int(11) NOT NULL DEFAULT 0,
  `speed_up` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `speed_mbps` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plan_name` (`plan_name`)
) ENGINE=InnoDB AUTO_INCREMENT=79 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `radius_accounting`
--

DROP TABLE IF EXISTS `radius_accounting`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radius_accounting` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) DEFAULT NULL,
  `session_id` varchar(64) DEFAULT NULL,
  `nas_ip` varchar(64) DEFAULT NULL,
  `framed_ip` varchar(64) DEFAULT NULL,
  `session_start` datetime DEFAULT NULL,
  `session_stop` datetime DEFAULT NULL,
  `input_octets` bigint(20) DEFAULT NULL,
  `output_octets` bigint(20) DEFAULT NULL,
  `session_time` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_radius_username` (`username`),
  KEY `idx_radius_active` (`username`,`session_stop`),
  KEY `idx_radius_session` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `radius_disconnect_queue`
--

DROP TABLE IF EXISTS `radius_disconnect_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radius_disconnect_queue` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) DEFAULT NULL,
  `nas_ip` varchar(64) DEFAULT NULL,
  `reason` varchar(128) DEFAULT NULL,
  `status` enum('PENDING','SENT') DEFAULT 'PENDING',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `radius_profiles`
--

DROP TABLE IF EXISTS `radius_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radius_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_name` varchar(64) DEFAULT NULL,
  `rate_limit` varchar(64) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `profile_name` (`profile_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `radius_settings`
--

DROP TABLE IF EXISTS `radius_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radius_settings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `host` varchar(255) NOT NULL,
  `db_user` varchar(190) NOT NULL,
  `db_password` varchar(255) NOT NULL,
  `db_name` varchar(190) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_radius_settings_active` (`is_active`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `radius_users`
--

DROP TABLE IF EXISTS `radius_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radius_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) NOT NULL,
  `username` varchar(64) DEFAULT NULL,
  `password` varchar(64) DEFAULT NULL,
  `profile_id` int(11) DEFAULT NULL,
  `status` enum('ACTIVE','SUSPENDED') DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `service_id` (`service_id`),
  KEY `profile_id` (`profile_id`),
  CONSTRAINT `radius_users_ibfk_1` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`),
  CONSTRAINT `radius_users_ibfk_2` FOREIGN KEY (`profile_id`) REFERENCES `radius_profiles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rate_limits`
--

DROP TABLE IF EXISTS `rate_limits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rate_limits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(45) NOT NULL,
  `requests` int(11) DEFAULT 0,
  `last_request` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ip_address` (`ip_address`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `role_permissions`
--

DROP TABLE IF EXISTS `role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permissions` (
  `role_id` int(10) unsigned NOT NULL,
  `permission_id` int(10) unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`role_id`,`permission_id`),
  KEY `fk_role_permissions_permission` (`permission_id`),
  CONSTRAINT `fk_role_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_role_permissions_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `is_system` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roles_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `router_config_deployments`
--

DROP TABLE IF EXISTS `router_config_deployments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `router_config_deployments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `router_type` enum('CORE','FRR') NOT NULL,
  `status` enum('SUCCESS','FAILED') NOT NULL,
  `config_hash` char(64) NOT NULL,
  `result_message` text DEFAULT NULL,
  `performed_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_router_deployments_type` (`router_type`,`created_at`),
  KEY `fk_router_deployment_user` (`performed_by`),
  CONSTRAINT `fk_router_deployment_user` FOREIGN KEY (`performed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `router_core_settings`
--

DROP TABLE IF EXISTS `router_core_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `router_core_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `host` varchar(255) NOT NULL,
  `port` int(11) NOT NULL DEFAULT 22,
  `username` varchar(100) NOT NULL,
  `password` text DEFAULT NULL,
  `known_host_key` text DEFAULT NULL,
  `host_key_fingerprint` varchar(128) DEFAULT NULL,
  `config_json` longtext NOT NULL,
  `rendered_config` longtext NOT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_router_core_updated_by` (`updated_by`),
  CONSTRAINT `fk_router_core_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `router_frr_settings`
--

DROP TABLE IF EXISTS `router_frr_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `router_frr_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `config_json` longtext NOT NULL,
  `rendered_config` longtext NOT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_router_frr_updated_by` (`updated_by`),
  CONSTRAINT `fk_router_frr_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_provisioning_bindings`
--

DROP TABLE IF EXISTS `service_provisioning_bindings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_provisioning_bindings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) NOT NULL,
  `ont_id` int(11) DEFAULT NULL,
  `ont_serial` varchar(64) DEFAULT NULL,
  `olt_id` int(11) DEFAULT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `network_box_id` int(11) DEFAULT NULL,
  `splitter_id` int(11) DEFAULT NULL,
  `splitter_output_port_id` int(11) DEFAULT NULL,
  `parent_box_id` int(11) DEFAULT NULL,
  `cvlan_network_vlan_id` int(11) DEFAULT NULL,
  `cvlan` int(11) DEFAULT NULL,
  `svlan` int(11) DEFAULT NULL,
  `ont_assigned_id` int(11) DEFAULT NULL,
  `global_id` int(11) DEFAULT NULL,
  `pppoe_service_port` int(11) DEFAULT NULL,
  `tr069_service_port` int(11) DEFAULT NULL,
  `lineprofile_id` int(11) DEFAULT NULL,
  `srvprofile_id` int(11) DEFAULT NULL,
  `tr069_profile_id` int(11) DEFAULT NULL,
  `internet_wan_profile_id` int(11) DEFAULT NULL,
  `tr069_wan_profile_id` int(11) DEFAULT NULL,
  `assigned_at` datetime DEFAULT NULL,
  `installed_at` datetime DEFAULT NULL,
  `activated_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_spb_service` (`service_id`),
  UNIQUE KEY `uniq_spb_cvlan_network_vlan_id` (`cvlan_network_vlan_id`),
  KEY `idx_spb_ont_serial` (`ont_serial`),
  KEY `idx_spb_olt_port` (`olt_port_id`),
  KEY `idx_spb_splitter_output` (`splitter_output_port_id`),
  KEY `fk_spb_ont` (`ont_id`),
  KEY `fk_spb_olt` (`olt_id`),
  KEY `fk_spb_network_box` (`network_box_id`),
  KEY `fk_spb_splitter` (`splitter_id`),
  KEY `idx_spb_cvlan_network_vlan_id` (`cvlan_network_vlan_id`),
  CONSTRAINT `fk_spb_network_box` FOREIGN KEY (`network_box_id`) REFERENCES `network_boxes` (`id`),
  CONSTRAINT `fk_spb_olt` FOREIGN KEY (`olt_id`) REFERENCES `olt_devices` (`id`),
  CONSTRAINT `fk_spb_olt_port` FOREIGN KEY (`olt_port_id`) REFERENCES `olt_ports` (`id`),
  CONSTRAINT `fk_spb_ont` FOREIGN KEY (`ont_id`) REFERENCES `ont_devices` (`id`),
  CONSTRAINT `fk_spb_service` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`),
  CONSTRAINT `fk_spb_splitter` FOREIGN KEY (`splitter_id`) REFERENCES `box_splitters` (`id`),
  CONSTRAINT `fk_spb_splitter_output` FOREIGN KEY (`splitter_output_port_id`) REFERENCES `splitter_output_ports` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_provisioning_job_logs`
--

DROP TABLE IF EXISTS `service_provisioning_job_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_provisioning_job_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_id` int(11) NOT NULL,
  `stage` varchar(64) NOT NULL,
  `action` varchar(128) NOT NULL,
  `status` enum('INFO','SUCCESS','WARNING','FAILED') NOT NULL DEFAULT 'INFO',
  `message` text DEFAULT NULL,
  `payload_json` longtext DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_spjl_job` (`job_id`),
  CONSTRAINT `fk_spjl_job` FOREIGN KEY (`job_id`) REFERENCES `service_provisioning_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_provisioning_jobs`
--

DROP TABLE IF EXISTS `service_provisioning_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_provisioning_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_no` varchar(64) NOT NULL,
  `subscriber_id` int(11) NOT NULL,
  `service_id` int(11) DEFAULT NULL,
  `plan_id` int(11) DEFAULT NULL,
  `ont_id` int(11) DEFAULT NULL,
  `ont_serial` varchar(64) DEFAULT NULL,
  `olt_id` int(11) DEFAULT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `network_box_id` int(11) DEFAULT NULL,
  `splitter_id` int(11) DEFAULT NULL,
  `splitter_output_port_id` int(11) DEFAULT NULL,
  `frame` int(11) DEFAULT NULL,
  `slot` int(11) DEFAULT NULL,
  `port` int(11) DEFAULT NULL,
  `ont_assigned_id` int(11) DEFAULT NULL,
  `global_id` int(11) DEFAULT NULL,
  `cvlan` int(11) DEFAULT NULL,
  `svlan` int(11) DEFAULT NULL,
  `pppoe_service_port` int(11) DEFAULT NULL,
  `tr069_service_port` int(11) DEFAULT NULL,
  `lineprofile_id` int(11) DEFAULT NULL,
  `srvprofile_id` int(11) DEFAULT NULL,
  `tr069_profile_id` int(11) DEFAULT NULL,
  `internet_wan_profile_id` int(11) DEFAULT NULL,
  `tr069_wan_profile_id` int(11) DEFAULT NULL,
  `provision_mode` enum('FULL_AUTO','ASSISTED','MANUAL') NOT NULL DEFAULT 'ASSISTED',
  `job_status` enum('DRAFT','VALIDATING','READY','PROVISIONING','VERIFYING','SUCCESS','FAILED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  `current_stage` varchar(64) DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `request_payload` longtext DEFAULT NULL,
  `result_payload` longtext DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `started_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_spj_job_no` (`job_no`),
  KEY `idx_spj_subscriber` (`subscriber_id`),
  KEY `idx_spj_service` (`service_id`),
  KEY `idx_spj_status` (`job_status`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `settings` (
  `key` varchar(100) NOT NULL,
  `value` text DEFAULT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `splitter_output_ports`
--

DROP TABLE IF EXISTS `splitter_output_ports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `splitter_output_ports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `legacy_table` varchar(32) DEFAULT NULL,
  `legacy_id` int(11) DEFAULT NULL,
  `splitter_id` int(11) NOT NULL,
  `port_number` int(11) NOT NULL,
  `status` enum('AVAILABLE','USED','RESERVED','FAULTY') NOT NULL DEFAULT 'AVAILABLE',
  `connected_entity_type` enum('NONE','NAP','SUBSCRIBER','SERVICE') NOT NULL DEFAULT 'NONE',
  `connected_entity_id` int(11) DEFAULT NULL,
  `service_id` int(11) DEFAULT NULL,
  `reserved_label` varchar(128) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_splitter_port` (`splitter_id`,`port_number`),
  KEY `idx_status` (`status`),
  KEY `idx_connected_entity` (`connected_entity_type`,`connected_entity_id`),
  KEY `idx_service_id` (`service_id`),
  KEY `idx_legacy_ref` (`legacy_table`,`legacy_id`),
  CONSTRAINT `fk_splitter_output_ports_splitter` FOREIGN KEY (`splitter_id`) REFERENCES `box_splitters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `staff_attendance`
--

DROP TABLE IF EXISTS `staff_attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff_attendance` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `attendance_date` date NOT NULL,
  `time_in_at` datetime DEFAULT NULL,
  `time_out_at` datetime DEFAULT NULL,
  `status` enum('OFFLINE','AVAILABLE','BUSY','ON_BREAK','ON_SITE','TRAVELING') NOT NULL DEFAULT 'OFFLINE',
  `time_in_ip` varchar(64) DEFAULT NULL,
  `time_out_ip` varchar(64) DEFAULT NULL,
  `time_in_user_agent` text DEFAULT NULL,
  `time_in_latitude` decimal(10,7) DEFAULT NULL,
  `time_in_longitude` decimal(10,7) DEFAULT NULL,
  `time_out_user_agent` text DEFAULT NULL,
  `time_out_latitude` decimal(10,7) DEFAULT NULL,
  `time_out_longitude` decimal(10,7) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_staff_attendance_day` (`user_id`,`attendance_date`),
  UNIQUE KEY `uq_staff_attendance_user_date` (`user_id`,`attendance_date`),
  KEY `idx_staff_attendance_status` (`status`),
  KEY `idx_staff_attendance_date` (`attendance_date`),
  KEY `idx_staff_attendance_user` (`user_id`),
  CONSTRAINT `fk_staff_attendance_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `staff_attendance_logs`
--

DROP TABLE IF EXISTS `staff_attendance_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `staff_attendance_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `attendance_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `action` enum('TIME_IN','TIME_OUT','STATUS_CHANGE') NOT NULL,
  `old_status` varchar(50) DEFAULT NULL,
  `new_status` varchar(50) DEFAULT NULL,
  `ip_address` varchar(64) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_staff_attendance_logs_attendance` (`attendance_id`),
  KEY `idx_staff_attendance_logs_user` (`user_id`),
  KEY `idx_staff_attendance_logs_action` (`action`),
  KEY `idx_staff_attendance_logs_created` (`created_at`),
  CONSTRAINT `fk_staff_attendance_log_attendance` FOREIGN KEY (`attendance_id`) REFERENCES `staff_attendance` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_staff_attendance_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subscriber_notes`
--

DROP TABLE IF EXISTS `subscriber_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `subscriber_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) NOT NULL,
  `note` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_note_service` (`service_id`),
  CONSTRAINT `fk_note_service` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subscriber_provisioning`
--

DROP TABLE IF EXISTS `subscriber_provisioning`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `subscriber_provisioning` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) NOT NULL,
  `nap_splitter_port` int(11) DEFAULT NULL,
  `ont_serial` varchar(64) DEFAULT NULL,
  `installed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `nap_port_id` int(11) DEFAULT NULL,
  `ont_id` int(11) DEFAULT NULL,
  `olt_port_id` int(11) DEFAULT NULL,
  `assigned_at` datetime DEFAULT NULL,
  `cvlan` int(11) DEFAULT NULL,
  `svlan` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `service_id` (`service_id`),
  KEY `idx_ont_serial` (`ont_serial`),
  KEY `fk_provision_ont` (`ont_id`),
  KEY `fk_provision_nap` (`nap_port_id`),
  KEY `fk_provision_olt` (`olt_port_id`),
  CONSTRAINT `fk_provision_nap` FOREIGN KEY (`nap_port_id`) REFERENCES `nap_ports` (`id`),
  CONSTRAINT `fk_provision_olt` FOREIGN KEY (`olt_port_id`) REFERENCES `olt_ports` (`id`),
  CONSTRAINT `fk_provision_ont` FOREIGN KEY (`ont_id`) REFERENCES `ont_devices` (`id`),
  CONSTRAINT `fk_provision_service` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subscriber_services`
--

DROP TABLE IF EXISTS `subscriber_services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `subscriber_services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subscriber_id` int(11) NOT NULL,
  `ppp_username` varchar(64) DEFAULT NULL,
  `ppp_password` varchar(64) DEFAULT NULL,
  `plan_id` int(11) DEFAULT NULL,
  `account_type` enum('PREPAID','POSTPAID') DEFAULT 'POSTPAID',
  `status` enum('PENDING','ACTIVE','SUSPENDED','TERMINATED') DEFAULT 'PENDING',
  `next_due_date` date DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `service_number` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ppp_username` (`ppp_username`),
  UNIQUE KEY `service_number` (`service_number`),
  KEY `fk_service_subscriber` (`subscriber_id`),
  KEY `idx_service_plan` (`plan_id`),
  CONSTRAINT `fk_service_plan` FOREIGN KEY (`plan_id`) REFERENCES `plans` (`id`),
  CONSTRAINT `fk_service_subscriber` FOREIGN KEY (`subscriber_id`) REFERENCES `subscribers` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subscribers`
--

DROP TABLE IF EXISTS `subscribers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `subscribers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `account_number` bigint(20) DEFAULT NULL,
  `full_name` varchar(128) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `contact_number` varchar(32) DEFAULT NULL,
  `email` varchar(128) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_number` (`account_number`),
  UNIQUE KEY `uq_subscribers_user_id` (`user_id`),
  KEY `idx_customers_status` (`status`),
  KEY `idx_subscriber_account` (`account_number`),
  KEY `idx_subscriber_name` (`full_name`),
  KEY `idx_subscriber_phone` (`contact_number`),
  KEY `idx_subscribers_user_id` (`user_id`),
  CONSTRAINT `fk_subscribers_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_config`
--

DROP TABLE IF EXISTS `system_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `config_key` varchar(64) DEFAULT NULL,
  `config_value` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_key` (`config_key`)
) ENGINE=InnoDB AUTO_INCREMENT=191 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `technician_profiles`
--

DROP TABLE IF EXISTS `technician_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `technician_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `employee_no` varchar(64) DEFAULT NULL,
  `mobile_number` varchar(32) DEFAULT NULL,
  `team` varchar(64) DEFAULT NULL,
  `service_area` varchar(128) DEFAULT NULL,
  `skill_level` enum('JUNIOR','SENIOR','LEAD') DEFAULT 'JUNIOR',
  `vehicle` varchar(128) DEFAULT NULL,
  `vehicle_plate` varchar(32) DEFAULT NULL,
  `emergency_contact` varchar(128) DEFAULT NULL,
  `emergency_number` varchar(32) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `fk_technician_profiles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `technicians`
--

DROP TABLE IF EXISTS `technicians`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `technicians` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) DEFAULT NULL,
  `contact_number` varchar(32) DEFAULT NULL,
  `email` varchar(128) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ticket_messages`
--

DROP TABLE IF EXISTS `ticket_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ticket_id` int(11) NOT NULL,
  `sender_type` enum('SUBSCRIBER','STAFF','SYSTEM') NOT NULL,
  `sender_user_id` int(11) DEFAULT NULL,
  `message` text NOT NULL,
  `is_internal` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_ticket_messages_user` (`sender_user_id`),
  KEY `idx_ticket_messages_ticket` (`ticket_id`),
  KEY `idx_ticket_messages_created_at` (`created_at`),
  CONSTRAINT `fk_ticket_messages_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ticket_messages_user` FOREIGN KEY (`sender_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ticket_status_logs`
--

DROP TABLE IF EXISTS `ticket_status_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket_status_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ticket_id` int(11) NOT NULL,
  `old_status` varchar(50) DEFAULT NULL,
  `new_status` varchar(50) NOT NULL,
  `changed_by_user_id` int(11) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_ticket_status_logs_user` (`changed_by_user_id`),
  KEY `idx_ticket_status_logs_ticket` (`ticket_id`),
  KEY `idx_ticket_status_logs_created_at` (`created_at`),
  CONSTRAINT `fk_ticket_status_logs_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ticket_status_logs_user` FOREIGN KEY (`changed_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tickets`
--

DROP TABLE IF EXISTS `tickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tickets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ticket_no` varchar(32) NOT NULL,
  `subscriber_id` int(11) NOT NULL,
  `service_id` int(11) DEFAULT NULL,
  `category` enum('INTERNET','BILLING','INSTALLATION','TECHNICAL_VISIT','ACCOUNT','OTHERS') NOT NULL DEFAULT 'INTERNET',
  `subject` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `priority` enum('LOW','MEDIUM','HIGH','URGENT') NOT NULL DEFAULT 'MEDIUM',
  `preferred_visit_date` date DEFAULT NULL,
  `preferred_visit_time` time DEFAULT NULL,
  `preferred_visit_notes` text DEFAULT NULL,
  `status` enum('OPEN','IN_PROGRESS','WAITING_CUSTOMER','WAITING_TECHNICIAN','WAITING_CUSTOMER_SCHEDULE','VISIT_SCHEDULED','RESOLVED','CLOSED','CANCELLED') NOT NULL DEFAULT 'OPEN',
  `assigned_user_id` int(11) DEFAULT NULL,
  `work_order_id` int(11) DEFAULT NULL,
  `created_by_type` enum('SUBSCRIBER','STAFF','SYSTEM') NOT NULL DEFAULT 'SUBSCRIBER',
  `created_by_user_id` int(11) DEFAULT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ticket_no` (`ticket_no`),
  KEY `fk_tickets_work_order` (`work_order_id`),
  KEY `idx_tickets_subscriber` (`subscriber_id`),
  KEY `idx_tickets_service` (`service_id`),
  KEY `idx_tickets_status` (`status`),
  KEY `idx_tickets_priority` (`priority`),
  KEY `idx_tickets_category` (`category`),
  KEY `idx_tickets_assigned_user` (`assigned_user_id`),
  KEY `idx_tickets_created_at` (`created_at`),
  KEY `idx_tickets_preferred_visit_date` (`preferred_visit_date`),
  KEY `fk_tickets_created_by_user` (`created_by_user_id`),
  CONSTRAINT `fk_tickets_assigned_user` FOREIGN KEY (`assigned_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_tickets_created_by_user` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tickets_service` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`),
  CONSTRAINT `fk_tickets_subscriber` FOREIGN KEY (`subscriber_id`) REFERENCES `subscribers` (`id`),
  CONSTRAINT `fk_tickets_work_order` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_permission_overrides`
--

DROP TABLE IF EXISTS `user_permission_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_permission_overrides` (
  `user_id` int(11) NOT NULL,
  `permission_id` int(10) unsigned NOT NULL,
  `effect` enum('ALLOW','DENY') NOT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`user_id`,`permission_id`),
  KEY `idx_user_permission_effect` (`user_id`,`effect`),
  KEY `fk_user_permission_permission` (`permission_id`),
  KEY `fk_user_permission_creator` (`created_by`),
  CONSTRAINT `fk_user_permission_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_user_permission_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_permission_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) DEFAULT NULL,
  `full_name` varchar(128) DEFAULT NULL,
  `email` varchar(128) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `role` enum('SUPERADMIN','NOC','SUPPORT','BILLING','TECHNICIAN','SUBSCRIBER') DEFAULT 'SUPPORT',
  `status` enum('ACTIVE','DISABLED') DEFAULT 'ACTIVE',
  `last_login` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vlan_pool`
--

DROP TABLE IF EXISTS `vlan_pool`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `vlan_pool` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) DEFAULT NULL,
  `vlan_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('FREE','RESERVED','USED') DEFAULT 'FREE',
  `olt_port_id` int(11) DEFAULT NULL,
  `reserved_at` datetime DEFAULT NULL,
  `used_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vlan_pool_service_vlan` (`service_id`,`vlan_id`),
  KEY `vlan_id` (`vlan_id`),
  KEY `idx_vlan_pool_status` (`status`),
  KEY `idx_vlan_pool_port` (`olt_port_id`),
  CONSTRAINT `vlan_pool_ibfk_1` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`),
  CONSTRAINT `vlan_pool_ibfk_2` FOREIGN KEY (`vlan_id`) REFERENCES `network_vlans` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `work_order_assignments`
--

DROP TABLE IF EXISTS `work_order_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_order_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `work_order_id` int(11) DEFAULT NULL,
  `technician_id` int(11) DEFAULT NULL,
  `assigned_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_workorder_assign` (`work_order_id`),
  KEY `fk_workorder_tech` (`technician_id`),
  CONSTRAINT `fk_workorder_assign` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`),
  CONSTRAINT `fk_workorder_tech` FOREIGN KEY (`technician_id`) REFERENCES `technicians` (`id`),
  CONSTRAINT `work_order_assignments_ibfk_1` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`),
  CONSTRAINT `work_order_assignments_ibfk_2` FOREIGN KEY (`technician_id`) REFERENCES `technicians` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `work_order_attachments`
--

DROP TABLE IF EXISTS `work_order_attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_order_attachments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `work_order_id` int(11) NOT NULL,
  `uploaded_by_user_id` int(11) DEFAULT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_type` varchar(100) DEFAULT NULL,
  `file_size` int(11) DEFAULT NULL,
  `attachment_type` enum('BEFORE','AFTER','ONT','NAP','OTHER') NOT NULL DEFAULT 'OTHER',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_woa_work_order_id` (`work_order_id`),
  KEY `idx_woa_uploaded_by` (`uploaded_by_user_id`),
  KEY `idx_woa_type` (`attachment_type`),
  CONSTRAINT `fk_work_order_attachment_order` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_work_order_attachment_user` FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `work_order_notes`
--

DROP TABLE IF EXISTS `work_order_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_order_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `work_order_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `note` text NOT NULL,
  `note_type` enum('NOTE','STATUS','CHECK_IN','COMPLETION','PHOTO','SYSTEM') NOT NULL DEFAULT 'NOTE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_work_order_notes_work_order_id` (`work_order_id`),
  KEY `idx_work_order_notes_user_id` (`user_id`),
  KEY `idx_work_order_notes_note_type` (`note_type`),
  CONSTRAINT `fk_work_order_note_order` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_work_order_note_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `work_order_status_logs`
--

DROP TABLE IF EXISTS `work_order_status_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_order_status_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `work_order_id` int(11) NOT NULL,
  `old_status` varchar(50) DEFAULT NULL,
  `new_status` varchar(50) NOT NULL,
  `changed_by_user_id` int(11) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_work_order_status_logs_wo` (`work_order_id`),
  KEY `idx_work_order_status_logs_user` (`changed_by_user_id`),
  KEY `idx_work_order_status_logs_created` (`created_at`),
  CONSTRAINT `fk_work_order_status_order` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_work_order_status_user` FOREIGN KEY (`changed_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `work_order_tasks`
--

DROP TABLE IF EXISTS `work_order_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_order_tasks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `work_order_id` int(11) NOT NULL,
  `task_name` varchar(255) NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  `is_completed` tinyint(1) NOT NULL DEFAULT 0,
  `completed_at` datetime DEFAULT NULL,
  `completed_by_user_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_work_order_tasks_wo` (`work_order_id`),
  KEY `idx_work_order_tasks_completed` (`is_completed`),
  KEY `fk_work_order_task_user` (`completed_by_user_id`),
  CONSTRAINT `fk_work_order_task_order` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_work_order_task_user` FOREIGN KEY (`completed_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `work_orders`
--

DROP TABLE IF EXISTS `work_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `work_order_no` varchar(50) DEFAULT NULL,
  `source_type` enum('TICKET','SERVICE_PROVISIONING','MANUAL') NOT NULL DEFAULT 'MANUAL',
  `source_id` int(11) DEFAULT NULL,
  `ticket_id` int(11) DEFAULT NULL,
  `subscriber_id` int(11) NOT NULL,
  `service_id` int(11) DEFAULT NULL,
  `work_order_type` enum('ONT_INSTALLATION','TECHNICAL_VISIT','NO_INTERNET','LOS','RELOCATION','REPAIR','RECONNECTION','DISCONNECTION','NAP_CHECK','DROP_CABLE_REPLACEMENT','OTHER') NOT NULL DEFAULT 'TECHNICAL_VISIT',
  `title` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `priority` enum('LOW','MEDIUM','HIGH','URGENT') NOT NULL DEFAULT 'MEDIUM',
  `assigned_user_id` int(11) DEFAULT NULL,
  `type` enum('INSTALL','REPAIR','UPGRADE','DISCONNECT') DEFAULT NULL,
  `status` enum('OPEN','ASSIGNED','IN_PROGRESS','ON_SITE','COMPLETED','CANCELLED','FAILED') NOT NULL DEFAULT 'OPEN',
  `scheduled_date` date DEFAULT NULL,
  `scheduled_time` time DEFAULT NULL,
  `check_in_at` datetime DEFAULT NULL,
  `check_in_latitude` decimal(10,7) DEFAULT NULL,
  `check_in_longitude` decimal(10,7) DEFAULT NULL,
  `location` text DEFAULT NULL,
  `contact_name` varchar(255) DEFAULT NULL,
  `contact_number` varchar(100) DEFAULT NULL,
  `started_at` datetime DEFAULT NULL,
  `arrived_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  `completion_notes` text DEFAULT NULL,
  `failure_reason` text DEFAULT NULL,
  `created_by_user_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_work_orders_no` (`work_order_no`),
  KEY `subscriber_id` (`subscriber_id`),
  KEY `service_id` (`service_id`),
  KEY `idx_work_orders_ticket` (`ticket_id`),
  KEY `idx_work_orders_assigned_user` (`assigned_user_id`),
  KEY `idx_work_orders_status` (`status`),
  KEY `idx_work_orders_type` (`work_order_type`),
  KEY `idx_work_orders_source` (`source_type`,`source_id`),
  KEY `fk_work_orders_creator` (`created_by_user_id`),
  CONSTRAINT `fk_work_orders_assignee` FOREIGN KEY (`assigned_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_work_orders_creator` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_work_orders_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`id`) ON DELETE SET NULL,
  CONSTRAINT `work_orders_ibfk_1` FOREIGN KEY (`subscriber_id`) REFERENCES `subscribers` (`id`),
  CONSTRAINT `work_orders_ibfk_2` FOREIGN KEY (`service_id`) REFERENCES `subscriber_services` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping events for database 'portal'
--

--
-- Dumping routines for database 'portal'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-03 11:54:10

-- Deployment administrator (change this password after first login).
INSERT INTO `users` (`username`, `full_name`, `email`, `password`, `role`, `status`)
VALUES ("billing", "Billing Administrator", "billing@localhost", "$2y$10$5prYH.LrZtNELI23Mg764eGq/Bi4TuyHFNCXli6LYMHbf8eF5xqxa", "SUPERADMIN", "ACTIVE");
