-- +goose Up
-- Strings are text because Postgres, unlike SQLite, enforces varchar lengths.
-- Dates are timestamp without time zone: gophish writes UTC only, and the
-- driver reads these columns back as UTC, as MySQL does with loc=UTC.
CREATE TABLE "users" (
    "id" bigserial PRIMARY KEY,
    "username" text NOT NULL UNIQUE,
    "hash" text,
    "api_key" text NOT NULL UNIQUE,
    "role_id" bigint,
    "password_change_required" boolean,
    "last_login" timestamp,
    "account_locked" boolean
);

CREATE TABLE "roles" (
    "id" bigserial PRIMARY KEY,
    "slug" text NOT NULL UNIQUE,
    "name" text NOT NULL UNIQUE,
    "description" text
);

CREATE TABLE "permissions" (
    "id" bigserial PRIMARY KEY,
    "slug" text NOT NULL UNIQUE,
    "name" text NOT NULL UNIQUE,
    "description" text
);

CREATE TABLE "role_permissions" (
    "role_id" bigint NOT NULL,
    "permission_id" bigint NOT NULL
);

CREATE TABLE "templates" (
    "id" bigserial PRIMARY KEY,
    "user_id" bigint,
    "name" text,
    "subject" text,
    "text" text,
    "html" text,
    "modified_date" timestamp,
    "envelope_sender" text
);

CREATE TABLE "attachments" (
    "id" bigserial PRIMARY KEY,
    "template_id" bigint,
    "content" text,
    "type" text,
    "name" text
);

CREATE TABLE "pages" (
    "id" bigserial PRIMARY KEY,
    "user_id" bigint,
    "name" text,
    "html" text,
    "modified_date" timestamp,
    "capture_credentials" boolean,
    "capture_passwords" boolean,
    "redirect_url" text
);

CREATE TABLE "groups" (
    "id" bigserial PRIMARY KEY,
    "user_id" bigint,
    "name" text,
    "modified_date" timestamp
);

CREATE TABLE "targets" (
    "id" bigserial PRIMARY KEY,
    "first_name" text,
    "last_name" text,
    "email" text,
    "position" text
);

CREATE TABLE "group_targets" (
    "group_id" bigint,
    "target_id" bigint
);

CREATE TABLE "smtp" (
    "id" bigserial PRIMARY KEY,
    "user_id" bigint,
    "interface_type" text,
    "name" text,
    "host" text,
    "username" text,
    "password" text,
    "from_address" text,
    "modified_date" timestamp,
    "ignore_cert_errors" boolean
);

CREATE TABLE "headers" (
    "id" bigserial PRIMARY KEY,
    "key" text,
    "value" text,
    "smtp_id" bigint
);

CREATE TABLE "campaigns" (
    "id" bigserial PRIMARY KEY,
    "user_id" bigint,
    "name" text NOT NULL,
    "created_date" timestamp,
    "completed_date" timestamp,
    "template_id" bigint,
    "page_id" bigint,
    "status" text,
    "url" text,
    "smtp_id" bigint,
    "launch_date" timestamp,
    "send_by_date" timestamp
);

CREATE TABLE "results" (
    "id" bigserial PRIMARY KEY,
    "campaign_id" bigint,
    "user_id" bigint,
    "r_id" text,
    "email" text,
    "first_name" text,
    "last_name" text,
    "status" text NOT NULL,
    "ip" text,
    "latitude" double precision,
    "longitude" double precision,
    "position" text,
    "send_date" timestamp,
    "reported" boolean DEFAULT false,
    "modified_date" timestamp
);

CREATE TABLE "events" (
    "id" bigserial PRIMARY KEY,
    "campaign_id" bigint,
    "email" text,
    "time" timestamp,
    "message" text,
    "details" text
);

CREATE TABLE "mail_logs" (
    "id" bigserial PRIMARY KEY,
    "campaign_id" bigint,
    "user_id" bigint,
    "send_date" timestamp,
    "send_attempt" integer,
    "r_id" text,
    "processing" boolean
);

CREATE TABLE "email_requests" (
    "id" bigserial PRIMARY KEY,
    "user_id" bigint,
    "template_id" bigint,
    "page_id" bigint,
    "first_name" text,
    "last_name" text,
    "email" text,
    "position" text,
    "url" text,
    "r_id" text,
    "from_address" text
);

CREATE TABLE "webhooks" (
    "id" bigserial PRIMARY KEY,
    "name" text,
    "url" text,
    "secret" text,
    "is_active" boolean DEFAULT false
);

CREATE TABLE "imap" (
    "user_id" bigint,
    "host" text,
    "port" integer,
    "username" text,
    "password" text,
    "modified_date" timestamp,
    "tls" boolean,
    "enabled" boolean,
    "folder" text,
    "restrict_domain" text,
    "delete_reported_campaign_email" boolean,
    "last_login" timestamp,
    "imap_freq" bigint,
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
