-- +goose Up
CREATE TABLE "users" (
    "id" integer primary key autoincrement,
    "username" varchar(255) NOT NULL UNIQUE,
    "hash" varchar(255),
    "api_key" varchar(255) NOT NULL UNIQUE,
    "role_id" integer,
    "password_change_required" boolean,
    "last_login" datetime,
    "account_locked" boolean
);

CREATE TABLE "roles" (
    "id" integer primary key autoincrement,
    "slug" varchar(255) NOT NULL UNIQUE,
    "name" varchar(255) NOT NULL UNIQUE,
    "description" varchar(255)
);

CREATE TABLE "permissions" (
    "id" integer primary key autoincrement,
    "slug" varchar(255) NOT NULL UNIQUE,
    "name" varchar(255) NOT NULL UNIQUE,
    "description" varchar(255)
);

CREATE TABLE "role_permissions" (
    "role_id" integer NOT NULL,
    "permission_id" integer NOT NULL
);

CREATE TABLE "templates" (
    "id" integer primary key autoincrement,
    "user_id" bigint,
    "name" varchar(255),
    "subject" varchar(255),
    "text" varchar(255),
    "html" varchar(255),
    "modified_date" datetime,
    "envelope_sender" varchar(255)
);

CREATE TABLE "attachments" (
    "id" integer primary key autoincrement,
    "template_id" bigint,
    "content" varchar(255),
    "type" varchar(255),
    "name" varchar(255)
);

CREATE TABLE "pages" (
    "id" integer primary key autoincrement,
    "user_id" bigint,
    "name" varchar(255),
    "html" varchar(255),
    "modified_date" datetime,
    "capture_credentials" boolean,
    "capture_passwords" boolean,
    "redirect_url" varchar(255)
);

CREATE TABLE "groups" (
    "id" integer primary key autoincrement,
    "user_id" bigint,
    "name" varchar(255),
    "modified_date" datetime
);

CREATE TABLE "targets" (
    "id" integer primary key autoincrement,
    "first_name" varchar(255),
    "last_name" varchar(255),
    "email" varchar(255),
    "position" varchar(255)
);

CREATE TABLE "group_targets" (
    "group_id" bigint,
    "target_id" bigint
);

CREATE TABLE "smtp" (
    "id" integer primary key autoincrement,
    "user_id" bigint,
    "interface_type" varchar(255),
    "name" varchar(255),
    "host" varchar(255),
    "username" varchar(255),
    "password" varchar(255),
    "from_address" varchar(255),
    "modified_date" datetime default CURRENT_TIMESTAMP,
    "ignore_cert_errors" boolean
);

CREATE TABLE "headers" (
    "id" integer primary key autoincrement,
    "key" varchar(255),
    "value" varchar(255),
    "smtp_id" bigint
);

CREATE TABLE "campaigns" (
    "id" integer primary key autoincrement,
    "user_id" bigint,
    "name" varchar(255) NOT NULL,
    "created_date" datetime,
    "completed_date" datetime,
    "template_id" bigint,
    "page_id" bigint,
    "status" varchar(255),
    "url" varchar(255),
    "smtp_id" bigint,
    "launch_date" datetime,
    "send_by_date" datetime
);

CREATE TABLE "results" (
    "id" integer primary key autoincrement,
    "campaign_id" bigint,
    "user_id" bigint,
    "r_id" varchar(255),
    "email" varchar(255),
    "first_name" varchar(255),
    "last_name" varchar(255),
    "status" varchar(255) NOT NULL,
    "ip" varchar(255),
    "latitude" real,
    "longitude" real,
    "position" varchar(255),
    "send_date" datetime,
    "reported" boolean default 0,
    "modified_date" datetime
);

CREATE TABLE "events" (
    "id" integer primary key autoincrement,
    "campaign_id" bigint,
    "email" varchar(255),
    "time" datetime,
    "message" varchar(255),
    "details" blob
);

CREATE TABLE "mail_logs" (
    "id" integer primary key autoincrement,
    "campaign_id" integer,
    "user_id" integer,
    "send_date" datetime,
    "send_attempt" integer,
    "r_id" varchar(255),
    "processing" boolean
);

CREATE TABLE "email_requests" (
    "id" integer primary key autoincrement,
    "user_id" integer,
    "template_id" integer,
    "page_id" integer,
    "first_name" varchar(255),
    "last_name" varchar(255),
    "email" varchar(255),
    "position" varchar(255),
    "url" varchar(255),
    "r_id" varchar(255),
    "from_address" varchar(255)
);

CREATE TABLE "webhooks" (
    "id" integer primary key autoincrement,
    "name" varchar(255),
    "url" varchar(1000),
    "secret" varchar(255),
    "is_active" boolean default 0
);

CREATE TABLE "imap" (
    "user_id" bigint,
    "host" varchar(255),
    "port" integer,
    "username" varchar(255),
    "password" varchar(255),
    "modified_date" datetime default CURRENT_TIMESTAMP,
    "tls" boolean,
    "enabled" boolean,
    "folder" varchar(255),
    "restrict_domain" varchar(255),
    "delete_reported_campaign_email" boolean,
    "last_login" datetime,
    "imap_freq" integer,
    "ignore_cert_errors" boolean
);

INSERT INTO "roles" ("slug", "name", "description") VALUES
    ('admin', 'Admin', 'System administrator with full permissions'),
    ('user', 'User', 'User role with edit access to objects and campaigns');

INSERT INTO "permissions" ("slug", "name", "description") VALUES
    ('view_objects', 'View Objects', 'View objects in Gophish'),
    ('modify_objects', 'Modify Objects', 'Create and edit objects in Gophish'),
    ('modify_system', 'Modify System', 'Manage system-wide configuration');

-- Admins may do everything, users may view and modify objects.
INSERT INTO "role_permissions" ("role_id", "permission_id")
SELECT r."id", p."id" FROM "roles" r, "permissions" p
WHERE r."slug" = 'admin' OR p."slug" IN ('view_objects', 'modify_objects');

-- +goose Down
DROP TABLE "imap";
DROP TABLE "webhooks";
DROP TABLE "email_requests";
DROP TABLE "mail_logs";
DROP TABLE "events";
DROP TABLE "results";
DROP TABLE "campaigns";
DROP TABLE "headers";
DROP TABLE "smtp";
DROP TABLE "group_targets";
DROP TABLE "targets";
DROP TABLE "groups";
DROP TABLE "pages";
DROP TABLE "attachments";
DROP TABLE "templates";
DROP TABLE "role_permissions";
DROP TABLE "permissions";
DROP TABLE "roles";
DROP TABLE "users";
