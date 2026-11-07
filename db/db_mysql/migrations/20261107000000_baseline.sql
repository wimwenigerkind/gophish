-- +goose Up
CREATE TABLE `users` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `username` varchar(255) NOT NULL UNIQUE,
    `hash` varchar(255),
    `api_key` varchar(255) NOT NULL UNIQUE,
    `role_id` int,
    `password_change_required` boolean,
    `last_login` datetime,
    `account_locked` boolean
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `roles` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `slug` varchar(255) NOT NULL UNIQUE,
    `name` varchar(255) NOT NULL UNIQUE,
    `description` varchar(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `permissions` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `slug` varchar(255) NOT NULL UNIQUE,
    `name` varchar(255) NOT NULL UNIQUE,
    `description` varchar(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `role_permissions` (
    `role_id` int NOT NULL,
    `permission_id` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `templates` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` bigint,
    `name` varchar(255),
    `subject` varchar(255),
    `text` text,
    `html` mediumtext,
    `modified_date` datetime,
    `envelope_sender` varchar(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `attachments` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `template_id` bigint,
    `content` longtext,
    `type` varchar(255),
    `name` varchar(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `pages` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` bigint,
    `name` varchar(255),
    `html` mediumtext,
    `modified_date` datetime,
    `capture_credentials` boolean,
    `capture_passwords` boolean,
    `redirect_url` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `groups` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` bigint,
    `name` varchar(255),
    `modified_date` datetime
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `targets` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `first_name` varchar(255),
    `last_name` varchar(255),
    `email` varchar(255),
    `position` varchar(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `group_targets` (
    `group_id` bigint,
    `target_id` bigint
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `smtp` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` bigint,
    `interface_type` varchar(255),
    `name` varchar(255),
    `host` varchar(255),
    `username` varchar(255),
    `password` varchar(255),
    `from_address` varchar(255),
    `modified_date` datetime,
    `ignore_cert_errors` boolean
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `headers` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `key` varchar(255),
    `value` varchar(255),
    `smtp_id` bigint
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `campaigns` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` bigint,
    `name` varchar(255) NOT NULL,
    `created_date` datetime,
    `completed_date` datetime,
    `template_id` bigint,
    `page_id` bigint,
    `status` varchar(255),
    `url` varchar(255),
    `smtp_id` bigint,
    `launch_date` datetime,
    `send_by_date` datetime
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `results` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `campaign_id` bigint,
    `user_id` bigint,
    `r_id` varchar(255),
    `email` varchar(255),
    `first_name` varchar(255),
    `last_name` varchar(255),
    `status` varchar(255) NOT NULL,
    `ip` varchar(255),
    `latitude` double,
    `longitude` double,
    `position` varchar(255),
    `send_date` datetime,
    `reported` boolean DEFAULT 0,
    `modified_date` datetime
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `events` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `campaign_id` bigint,
    `email` varchar(255),
    `time` datetime,
    `message` varchar(255),
    `details` blob
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `mail_logs` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `campaign_id` int,
    `user_id` int,
    `send_date` datetime,
    `send_attempt` int,
    `r_id` varchar(255),
    `processing` boolean
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `email_requests` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` int,
    `template_id` int,
    `page_id` int,
    `first_name` varchar(255),
    `last_name` varchar(255),
    `email` varchar(255),
    `position` varchar(255),
    `url` varchar(255),
    `r_id` varchar(255),
    `from_address` varchar(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `webhooks` (
    `id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` varchar(255),
    `url` varchar(1000),
    `secret` varchar(255),
    `is_active` boolean DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `imap` (
    `user_id` bigint,
    `host` varchar(255),
    `port` int,
    `username` varchar(255),
    `password` varchar(255),
    `modified_date` datetime,
    `tls` boolean,
    `enabled` boolean,
    `folder` varchar(255),
    `restrict_domain` varchar(255),
    `delete_reported_campaign_email` boolean,
    `last_login` datetime,
    `imap_freq` int,
    `ignore_cert_errors` boolean
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `roles` (`slug`, `name`, `description`) VALUES
    ('admin', 'Admin', 'System administrator with full permissions'),
    ('user', 'User', 'User role with edit access to objects and campaigns');

INSERT INTO `permissions` (`slug`, `name`, `description`) VALUES
    ('view_objects', 'View Objects', 'View objects in Gophish'),
    ('modify_objects', 'Modify Objects', 'Create and edit objects in Gophish'),
    ('modify_system', 'Modify System', 'Manage system-wide configuration');

-- Admins may do everything, users may view and modify objects.
INSERT INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r, `permissions` p
WHERE r.`slug` = 'admin' OR p.`slug` IN ('view_objects', 'modify_objects');

-- +goose Down
DROP TABLE `imap`;
DROP TABLE `webhooks`;
DROP TABLE `email_requests`;
DROP TABLE `mail_logs`;
DROP TABLE `events`;
DROP TABLE `results`;
DROP TABLE `campaigns`;
DROP TABLE `headers`;
DROP TABLE `smtp`;
DROP TABLE `group_targets`;
DROP TABLE `targets`;
DROP TABLE `groups`;
DROP TABLE `pages`;
DROP TABLE `attachments`;
DROP TABLE `templates`;
DROP TABLE `role_permissions`;
DROP TABLE `permissions`;
DROP TABLE `roles`;
DROP TABLE `users`;
