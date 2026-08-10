-- IT Service Management System
-- MySQL 8.0+ / InnoDB / utf8mb4
-- Import this file into a new or empty MySQL server.
-- No default administrator is inserted. Run: php scripts/create-admin.php

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS it_service_management
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE it_service_management;

DROP VIEW IF EXISTS vw_open_ticket_summary;

DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS ticket_custom_field_values;
DROP TABLE IF EXISTS custom_field_options;
DROP TABLE IF EXISTS custom_fields;
DROP TABLE IF EXISTS ticket_checklist_items;
DROP TABLE IF EXISTS checklist_template_items;
DROP TABLE IF EXISTS checklist_templates;
DROP TABLE IF EXISTS ticket_attachments;
DROP TABLE IF EXISTS ticket_messages;
DROP TABLE IF EXISTS ticket_status_history;
DROP TABLE IF EXISTS ticket_assignments;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS ticket_sequences;
DROP TABLE IF EXISTS ticket_priorities;
DROP TABLE IF EXISTS ticket_statuses;
DROP TABLE IF EXISTS ticket_categories;
DROP TABLE IF EXISTS device_history;
DROP TABLE IF EXISTS devices;
DROP TABLE IF EXISTS device_statuses;
DROP TABLE IF EXISTS device_types;
DROP TABLE IF EXISTS login_attempts;
DROP TABLE IF EXISTS password_reset_tokens;
DROP TABLE IF EXISTS user_sessions;
DROP TABLE IF EXISTS team_members;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS provider_users;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS service_providers;
DROP TABLE IF EXISTS service_provider_types;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS settings;

CREATE TABLE roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(60) NOT NULL,
  name_ar VARCHAR(120) NOT NULL,
  name_en VARCHAR(120) NOT NULL,
  description VARCHAR(500) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_roles_code (code)
) ENGINE=InnoDB;

CREATE TABLE permissions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(100) NOT NULL,
  name_ar VARCHAR(150) NOT NULL,
  module VARCHAR(60) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_permissions_code (code),
  KEY idx_permissions_module (module)
) ENGINE=InnoDB;

CREATE TABLE role_permissions (
  role_id BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles(id),
  CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions(id)
) ENGINE=InnoDB;

CREATE TABLE clients (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NULL,
  name_ar VARCHAR(180) NOT NULL,
  name_en VARCHAR(180) NULL,
  email VARCHAR(190) NULL,
  phone VARCHAR(40) NULL,
  notes TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_clients_code (code)
) ENGINE=InnoDB;

CREATE TABLE companies (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  client_id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(50) NULL,
  name_ar VARCHAR(180) NOT NULL,
  name_en VARCHAR(180) NULL,
  email_domain VARCHAR(190) NULL,
  phone VARCHAR(40) NULL,
  address TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_companies_code (code),
  KEY idx_companies_client (client_id),
  CONSTRAINT fk_companies_client FOREIGN KEY (client_id) REFERENCES clients(id)
) ENGINE=InnoDB;

CREATE TABLE departments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NULL,
  code VARCHAR(50) NULL,
  name_ar VARCHAR(150) NOT NULL,
  name_en VARCHAR(150) NULL,
  manager_user_id BIGINT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_departments_company (company_id),
  CONSTRAINT fk_departments_company FOREIGN KEY (company_id) REFERENCES companies(id)
) ENGINE=InnoDB;

CREATE TABLE locations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NULL,
  parent_id BIGINT UNSIGNED NULL,
  code VARCHAR(50) NULL,
  name_ar VARCHAR(180) NOT NULL,
  name_en VARCHAR(180) NULL,
  location_type VARCHAR(50) NULL,
  building VARCHAR(100) NULL,
  floor VARCHAR(50) NULL,
  room VARCHAR(50) NULL,
  address TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_locations_company (company_id),
  KEY idx_locations_parent (parent_id),
  CONSTRAINT fk_locations_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_locations_parent FOREIGN KEY (parent_id) REFERENCES locations(id)
) ENGINE=InnoDB;

CREATE TABLE service_provider_types (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL,
  name_ar VARCHAR(120) NOT NULL,
  name_en VARCHAR(120) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_provider_types_code (code)
) ENGINE=InnoDB;

CREATE TABLE service_providers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  provider_type_id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(50) NULL,
  name_ar VARCHAR(180) NOT NULL,
  name_en VARCHAR(180) NULL,
  contact_name VARCHAR(150) NULL,
  email VARCHAR(190) NULL,
  phone VARCHAR(40) NULL,
  emergency_phone VARCHAR(40) NULL,
  notes TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_service_providers_code (code),
  KEY idx_service_providers_type (provider_type_id),
  CONSTRAINT fk_service_providers_type FOREIGN KEY (provider_type_id) REFERENCES service_provider_types(id)
) ENGINE=InnoDB;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_type ENUM('INTERNAL','CLIENT','SERVICE_PROVIDER') NOT NULL DEFAULT 'INTERNAL',
  role_id BIGINT UNSIGNED NOT NULL,
  company_id BIGINT UNSIGNED NULL,
  provider_id BIGINT UNSIGNED NULL,
  department_id BIGINT UNSIGNED NULL,
  manager_user_id BIGINT UNSIGNED NULL,
  employee_number VARCHAR(80) NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(190) NOT NULL,
  phone VARCHAR(40) NULL,
  job_title VARCHAR(150) NULL,
  password_hash VARCHAR(255) NOT NULL,
  preferred_locale VARCHAR(10) NOT NULL DEFAULT 'ar',
  must_change_password TINYINT(1) NOT NULL DEFAULT 0,
  failed_login_count SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  locked_until DATETIME NULL,
  email_verified_at DATETIME NULL,
  last_login_at DATETIME NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  deactivated_at DATETIME NULL,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_users_email (email),
  UNIQUE KEY uq_users_employee_number (employee_number),
  KEY idx_users_role (role_id),
  KEY idx_users_company (company_id),
  KEY idx_users_provider (provider_id),
  KEY idx_users_department (department_id),
  KEY idx_users_manager (manager_user_id),
  KEY idx_users_active_name (is_active, first_name, last_name),
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id),
  CONSTRAINT fk_users_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_users_provider FOREIGN KEY (provider_id) REFERENCES service_providers(id),
  CONSTRAINT fk_users_department FOREIGN KEY (department_id) REFERENCES departments(id),
  CONSTRAINT fk_users_manager FOREIGN KEY (manager_user_id) REFERENCES users(id),
  CONSTRAINT fk_users_creator FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  CONSTRAINT chk_users_organization CHECK (
    (user_type = 'INTERNAL' AND company_id IS NULL AND provider_id IS NULL) OR
    (user_type = 'CLIENT' AND company_id IS NOT NULL AND provider_id IS NULL) OR
    (user_type = 'SERVICE_PROVIDER' AND company_id IS NULL AND provider_id IS NOT NULL)
  )
) ENGINE=InnoDB;

ALTER TABLE departments
  ADD CONSTRAINT fk_departments_manager FOREIGN KEY (manager_user_id) REFERENCES users(id);

CREATE TABLE provider_users (
  provider_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  is_primary_contact TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (provider_id, user_id),
  CONSTRAINT fk_provider_users_provider FOREIGN KEY (provider_id) REFERENCES service_providers(id),
  CONSTRAINT fk_provider_users_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE teams (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(60) NOT NULL,
  name_ar VARCHAR(150) NOT NULL,
  name_en VARCHAR(150) NULL,
  manager_user_id BIGINT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_teams_code (code),
  CONSTRAINT fk_teams_manager FOREIGN KEY (manager_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE team_members (
  team_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  is_team_lead TINYINT(1) NOT NULL DEFAULT 0,
  joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (team_id, user_id),
  CONSTRAINT fk_team_members_team FOREIGN KEY (team_id) REFERENCES teams(id),
  CONSTRAINT fk_team_members_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE user_sessions (
  id CHAR(64) PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  ip_address VARCHAR(45) NULL,
  user_agent VARCHAR(500) NULL,
  last_activity_at DATETIME NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_user_sessions_user (user_id),
  KEY idx_user_sessions_expiry (expires_at),
  CONSTRAINT fk_user_sessions_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE password_reset_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_password_reset_hash (token_hash),
  KEY idx_password_reset_user (user_id),
  KEY idx_password_reset_expiry (expires_at),
  CONSTRAINT fk_password_reset_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE login_attempts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL,
  ip_address VARCHAR(45) NULL,
  was_successful TINYINT(1) NOT NULL DEFAULT 0,
  attempted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_login_attempts_email_time (email, attempted_at),
  KEY idx_login_attempts_ip_time (ip_address, attempted_at)
) ENGINE=InnoDB;

CREATE TABLE device_types (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(60) NOT NULL,
  name_ar VARCHAR(120) NOT NULL,
  name_en VARCHAR(120) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_device_types_code (code)
) ENGINE=InnoDB;

CREATE TABLE device_statuses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(60) NOT NULL,
  name_ar VARCHAR(120) NOT NULL,
  name_en VARCHAR(120) NULL,
  is_assignable TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_device_statuses_code (code)
) ENGINE=InnoDB;

CREATE TABLE devices (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT UNSIGNED NULL,
  device_type_id BIGINT UNSIGNED NOT NULL,
  status_id BIGINT UNSIGNED NOT NULL,
  assigned_user_id BIGINT UNSIGNED NULL,
  location_id BIGINT UNSIGNED NULL,
  asset_tag VARCHAR(100) NOT NULL,
  hostname VARCHAR(190) NULL,
  serial_number VARCHAR(190) NULL,
  manufacturer VARCHAR(120) NULL,
  model VARCHAR(150) NULL,
  operating_system VARCHAR(150) NULL,
  ip_address VARCHAR(45) NULL,
  mac_address VARCHAR(30) NULL,
  purchase_date DATE NULL,
  warranty_end_date DATE NULL,
  notes TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_devices_asset_tag (asset_tag),
  UNIQUE KEY uq_devices_serial_number (serial_number),
  KEY idx_devices_company (company_id),
  KEY idx_devices_type (device_type_id),
  KEY idx_devices_status (status_id),
  KEY idx_devices_assigned_user (assigned_user_id),
  KEY idx_devices_location (location_id),
  CONSTRAINT fk_devices_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_devices_type FOREIGN KEY (device_type_id) REFERENCES device_types(id),
  CONSTRAINT fk_devices_status FOREIGN KEY (status_id) REFERENCES device_statuses(id),
  CONSTRAINT fk_devices_user FOREIGN KEY (assigned_user_id) REFERENCES users(id),
  CONSTRAINT fk_devices_location FOREIGN KEY (location_id) REFERENCES locations(id),
  CONSTRAINT fk_devices_creator FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE device_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  device_id BIGINT UNSIGNED NOT NULL,
  action ENUM('CREATED','ASSIGNED','UNASSIGNED','MOVED','STATUS_CHANGED','UPDATED','RETIRED','DISPOSED') NOT NULL,
  from_user_id BIGINT UNSIGNED NULL,
  to_user_id BIGINT UNSIGNED NULL,
  from_location_id BIGINT UNSIGNED NULL,
  to_location_id BIGINT UNSIGNED NULL,
  from_status_id BIGINT UNSIGNED NULL,
  to_status_id BIGINT UNSIGNED NULL,
  note TEXT NULL,
  changed_by_user_id BIGINT UNSIGNED NOT NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_device_history_device_time (device_id, changed_at),
  CONSTRAINT fk_device_history_device FOREIGN KEY (device_id) REFERENCES devices(id),
  CONSTRAINT fk_device_history_from_user FOREIGN KEY (from_user_id) REFERENCES users(id),
  CONSTRAINT fk_device_history_to_user FOREIGN KEY (to_user_id) REFERENCES users(id),
  CONSTRAINT fk_device_history_from_location FOREIGN KEY (from_location_id) REFERENCES locations(id),
  CONSTRAINT fk_device_history_to_location FOREIGN KEY (to_location_id) REFERENCES locations(id),
  CONSTRAINT fk_device_history_from_status FOREIGN KEY (from_status_id) REFERENCES device_statuses(id),
  CONSTRAINT fk_device_history_to_status FOREIGN KEY (to_status_id) REFERENCES device_statuses(id),
  CONSTRAINT fk_device_history_actor FOREIGN KEY (changed_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE ticket_categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parent_id BIGINT UNSIGNED NULL,
  default_team_id BIGINT UNSIGNED NULL,
  code VARCHAR(80) NOT NULL,
  name_ar VARCHAR(180) NOT NULL,
  name_en VARCHAR(180) NULL,
  description_ar TEXT NULL,
  icon VARCHAR(60) NULL,
  color VARCHAR(20) NULL,
  is_sensitive_default TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_ticket_categories_code (code),
  KEY idx_ticket_categories_parent (parent_id),
  CONSTRAINT fk_ticket_categories_parent FOREIGN KEY (parent_id) REFERENCES ticket_categories(id),
  CONSTRAINT fk_ticket_categories_team FOREIGN KEY (default_team_id) REFERENCES teams(id)
) ENGINE=InnoDB;

CREATE TABLE ticket_statuses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(60) NOT NULL,
  name_ar VARCHAR(120) NOT NULL,
  name_en VARCHAR(120) NOT NULL,
  color VARCHAR(20) NULL,
  is_open TINYINT(1) NOT NULL DEFAULT 1,
  pauses_sla TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_ticket_statuses_code (code)
) ENGINE=InnoDB;

CREATE TABLE ticket_priorities (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(60) NOT NULL,
  name_ar VARCHAR(120) NOT NULL,
  name_en VARCHAR(120) NOT NULL,
  color VARCHAR(20) NULL,
  first_response_minutes INT UNSIGNED NULL,
  resolution_minutes INT UNSIGNED NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_ticket_priorities_code (code)
) ENGINE=InnoDB;

CREATE TABLE ticket_sequences (
  sequence_year SMALLINT UNSIGNED PRIMARY KEY,
  last_number INT UNSIGNED NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE tickets (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ticket_number VARCHAR(30) NOT NULL,
  ticket_scope ENUM('INTERNAL','CLIENT') NOT NULL DEFAULT 'INTERNAL',
  ticket_kind ENUM('INCIDENT','SERVICE_REQUEST','ONBOARDING','OFFBOARDING','GENERAL_REQUEST') NOT NULL,
  company_id BIGINT UNSIGNED NULL,
  title VARCHAR(220) NOT NULL,
  description TEXT NOT NULL,
  category_id BIGINT UNSIGNED NOT NULL,
  priority_id BIGINT UNSIGNED NOT NULL,
  status_id BIGINT UNSIGNED NOT NULL,
  requester_user_id BIGINT UNSIGNED NOT NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  assigned_user_id BIGINT UNSIGNED NULL,
  assigned_team_id BIGINT UNSIGNED NULL,
  location_id BIGINT UNSIGNED NULL,
  device_id BIGINT UNSIGNED NULL,
  impact ENUM('LOW','MEDIUM','HIGH') NULL,
  urgency ENUM('LOW','MEDIUM','HIGH') NULL,
  source ENUM('WEB','EMAIL','PHONE','WALK_IN','API') NOT NULL DEFAULT 'WEB',
  is_sensitive TINYINT(1) NOT NULL DEFAULT 0,
  first_response_at DATETIME NULL,
  due_at DATETIME NULL,
  resolved_at DATETIME NULL,
  closed_at DATETIME NULL,
  resolution_summary TEXT NULL,
  cancellation_reason TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tickets_number (ticket_number),
  KEY idx_tickets_status_priority (status_id, priority_id),
  KEY idx_tickets_requester (requester_user_id),
  KEY idx_tickets_assigned_user (assigned_user_id),
  KEY idx_tickets_team (assigned_team_id),
  KEY idx_tickets_company (company_id),
  KEY idx_tickets_category (category_id),
  KEY idx_tickets_location (location_id),
  KEY idx_tickets_device (device_id),
  KEY idx_tickets_due (due_at),
  KEY idx_tickets_updated (updated_at),
  FULLTEXT KEY ftx_tickets_title_description (title, description),
  CONSTRAINT fk_tickets_company FOREIGN KEY (company_id) REFERENCES companies(id),
  CONSTRAINT fk_tickets_category FOREIGN KEY (category_id) REFERENCES ticket_categories(id),
  CONSTRAINT fk_tickets_priority FOREIGN KEY (priority_id) REFERENCES ticket_priorities(id),
  CONSTRAINT fk_tickets_status FOREIGN KEY (status_id) REFERENCES ticket_statuses(id),
  CONSTRAINT fk_tickets_requester FOREIGN KEY (requester_user_id) REFERENCES users(id),
  CONSTRAINT fk_tickets_creator FOREIGN KEY (created_by_user_id) REFERENCES users(id),
  CONSTRAINT fk_tickets_assignee FOREIGN KEY (assigned_user_id) REFERENCES users(id),
  CONSTRAINT fk_tickets_team FOREIGN KEY (assigned_team_id) REFERENCES teams(id),
  CONSTRAINT fk_tickets_location FOREIGN KEY (location_id) REFERENCES locations(id),
  CONSTRAINT fk_tickets_device FOREIGN KEY (device_id) REFERENCES devices(id),
  CONSTRAINT chk_tickets_scope CHECK (
    (ticket_scope = 'INTERNAL' AND company_id IS NULL) OR
    (ticket_scope = 'CLIENT' AND company_id IS NOT NULL)
  )
) ENGINE=InnoDB;

CREATE TABLE ticket_assignments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ticket_id BIGINT UNSIGNED NOT NULL,
  assignment_type ENUM('INTERNAL_USER','TEAM','SERVICE_PROVIDER') NOT NULL,
  assigned_user_id BIGINT UNSIGNED NULL,
  assigned_team_id BIGINT UNSIGNED NULL,
  service_provider_id BIGINT UNSIGNED NULL,
  assigned_by_user_id BIGINT UNSIGNED NOT NULL,
  assignment_status ENUM('ASSIGNED','ACCEPTED','REJECTED','IN_PROGRESS','VISIT_SCHEDULED','ON_SITE','COMPLETED','CANCELLED') NOT NULL DEFAULT 'ASSIGNED',
  scheduled_visit_at DATETIME NULL,
  accepted_at DATETIME NULL,
  ended_at DATETIME NULL,
  is_current TINYINT(1) NOT NULL DEFAULT 1,
  note TEXT NULL,
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_ticket_assignments_current (ticket_id, assignment_type, is_current),
  KEY idx_ticket_assignments_user (assigned_user_id),
  KEY idx_ticket_assignments_team (assigned_team_id),
  KEY idx_ticket_assignments_provider (service_provider_id),
  CONSTRAINT fk_ticket_assignments_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id),
  CONSTRAINT fk_ticket_assignments_user FOREIGN KEY (assigned_user_id) REFERENCES users(id),
  CONSTRAINT fk_ticket_assignments_team FOREIGN KEY (assigned_team_id) REFERENCES teams(id),
  CONSTRAINT fk_ticket_assignments_provider FOREIGN KEY (service_provider_id) REFERENCES service_providers(id),
  CONSTRAINT fk_ticket_assignments_actor FOREIGN KEY (assigned_by_user_id) REFERENCES users(id),
  CONSTRAINT chk_ticket_assignment_target CHECK (
    (assignment_type = 'INTERNAL_USER' AND assigned_user_id IS NOT NULL AND assigned_team_id IS NULL AND service_provider_id IS NULL) OR
    (assignment_type = 'TEAM' AND assigned_user_id IS NULL AND assigned_team_id IS NOT NULL AND service_provider_id IS NULL) OR
    (assignment_type = 'SERVICE_PROVIDER' AND assigned_user_id IS NULL AND assigned_team_id IS NULL AND service_provider_id IS NOT NULL)
  )
) ENGINE=InnoDB;

CREATE TABLE ticket_status_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ticket_id BIGINT UNSIGNED NOT NULL,
  from_status_id BIGINT UNSIGNED NULL,
  to_status_id BIGINT UNSIGNED NOT NULL,
  changed_by_user_id BIGINT UNSIGNED NOT NULL,
  note TEXT NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_ticket_status_history_ticket_time (ticket_id, changed_at),
  CONSTRAINT fk_ticket_status_history_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id),
  CONSTRAINT fk_ticket_status_history_from FOREIGN KEY (from_status_id) REFERENCES ticket_statuses(id),
  CONSTRAINT fk_ticket_status_history_to FOREIGN KEY (to_status_id) REFERENCES ticket_statuses(id),
  CONSTRAINT fk_ticket_status_history_actor FOREIGN KEY (changed_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE ticket_messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ticket_id BIGINT UNSIGNED NOT NULL,
  author_user_id BIGINT UNSIGNED NOT NULL,
  message MEDIUMTEXT NOT NULL,
  is_internal TINYINT(1) NOT NULL DEFAULT 0,
  is_system_message TINYINT(1) NOT NULL DEFAULT 0,
  edited_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_ticket_messages_ticket_time (ticket_id, created_at),
  CONSTRAINT fk_ticket_messages_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id),
  CONSTRAINT fk_ticket_messages_author FOREIGN KEY (author_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE ticket_attachments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ticket_id BIGINT UNSIGNED NOT NULL,
  message_id BIGINT UNSIGNED NULL,
  uploaded_by_user_id BIGINT UNSIGNED NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  stored_name VARCHAR(255) NOT NULL,
  storage_path VARCHAR(500) NOT NULL,
  mime_type VARCHAR(150) NOT NULL,
  extension VARCHAR(20) NULL,
  size_bytes BIGINT UNSIGNED NOT NULL,
  checksum_sha256 CHAR(64) NULL,
  is_internal TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_ticket_attachments_ticket (ticket_id),
  KEY idx_ticket_attachments_message (message_id),
  CONSTRAINT fk_ticket_attachments_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id),
  CONSTRAINT fk_ticket_attachments_message FOREIGN KEY (message_id) REFERENCES ticket_messages(id),
  CONSTRAINT fk_ticket_attachments_uploader FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE checklist_templates (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(80) NOT NULL,
  name_ar VARCHAR(180) NOT NULL,
  name_en VARCHAR(180) NULL,
  ticket_kind ENUM('INCIDENT','SERVICE_REQUEST','ONBOARDING','OFFBOARDING','GENERAL_REQUEST') NOT NULL,
  category_id BIGINT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_checklist_templates_code (code),
  CONSTRAINT fk_checklist_templates_category FOREIGN KEY (category_id) REFERENCES ticket_categories(id)
) ENGINE=InnoDB;

CREATE TABLE checklist_template_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  template_id BIGINT UNSIGNED NOT NULL,
  title_ar VARCHAR(255) NOT NULL,
  title_en VARCHAR(255) NULL,
  description_ar TEXT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_required TINYINT(1) NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  KEY idx_checklist_template_items_template (template_id, sort_order),
  CONSTRAINT fk_checklist_template_items_template FOREIGN KEY (template_id) REFERENCES checklist_templates(id)
) ENGINE=InnoDB;

CREATE TABLE ticket_checklist_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ticket_id BIGINT UNSIGNED NOT NULL,
  template_item_id BIGINT UNSIGNED NULL,
  title_ar VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_required TINYINT(1) NOT NULL DEFAULT 1,
  is_completed TINYINT(1) NOT NULL DEFAULT 0,
  completed_by_user_id BIGINT UNSIGNED NULL,
  completed_at DATETIME NULL,
  note TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_ticket_checklist_ticket (ticket_id, sort_order),
  CONSTRAINT fk_ticket_checklist_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id),
  CONSTRAINT fk_ticket_checklist_template_item FOREIGN KEY (template_item_id) REFERENCES checklist_template_items(id),
  CONSTRAINT fk_ticket_checklist_completed_by FOREIGN KEY (completed_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE custom_fields (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED NULL,
  ticket_kind ENUM('INCIDENT','SERVICE_REQUEST','ONBOARDING','OFFBOARDING','GENERAL_REQUEST') NULL,
  code VARCHAR(100) NOT NULL,
  label_ar VARCHAR(180) NOT NULL,
  label_en VARCHAR(180) NULL,
  field_type ENUM('TEXT','TEXTAREA','NUMBER','DATE','DATETIME','SELECT','MULTISELECT','CHECKBOX','USER','DEVICE') NOT NULL,
  help_text_ar VARCHAR(500) NULL,
  validation_rules JSON NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_required TINYINT(1) NOT NULL DEFAULT 0,
  is_sensitive TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_custom_fields_code (code),
  CONSTRAINT fk_custom_fields_category FOREIGN KEY (category_id) REFERENCES ticket_categories(id)
) ENGINE=InnoDB;

CREATE TABLE custom_field_options (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  custom_field_id BIGINT UNSIGNED NOT NULL,
  option_value VARCHAR(150) NOT NULL,
  label_ar VARCHAR(180) NOT NULL,
  label_en VARCHAR(180) NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_custom_field_option (custom_field_id, option_value),
  CONSTRAINT fk_custom_field_options_field FOREIGN KEY (custom_field_id) REFERENCES custom_fields(id)
) ENGINE=InnoDB;

CREATE TABLE ticket_custom_field_values (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ticket_id BIGINT UNSIGNED NOT NULL,
  custom_field_id BIGINT UNSIGNED NOT NULL,
  value_text MEDIUMTEXT NULL,
  value_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_ticket_custom_field (ticket_id, custom_field_id),
  CONSTRAINT fk_ticket_custom_values_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id),
  CONSTRAINT fk_ticket_custom_values_field FOREIGN KEY (custom_field_id) REFERENCES custom_fields(id)
) ENGINE=InnoDB;

CREATE TABLE notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  type VARCHAR(80) NOT NULL,
  title_ar VARCHAR(220) NOT NULL,
  body_ar TEXT NULL,
  action_url VARCHAR(500) NULL,
  channel ENUM('IN_APP','EMAIL','SMS','PUSH') NOT NULL DEFAULT 'IN_APP',
  status ENUM('PENDING','SENT','FAILED','READ') NOT NULL DEFAULT 'PENDING',
  read_at DATETIME NULL,
  sent_at DATETIME NULL,
  failed_reason VARCHAR(500) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_notifications_user_status (user_id, status, created_at),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_user_id BIGINT UNSIGNED NULL,
  action VARCHAR(120) NOT NULL,
  entity_type VARCHAR(80) NULL,
  entity_id BIGINT UNSIGNED NULL,
  old_values JSON NULL,
  new_values JSON NULL,
  ip_address VARCHAR(45) NULL,
  user_agent VARCHAR(500) NULL,
  request_id VARCHAR(100) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_audit_actor_time (actor_user_id, created_at),
  KEY idx_audit_entity (entity_type, entity_id, created_at),
  KEY idx_audit_action_time (action, created_at),
  CONSTRAINT fk_audit_logs_actor FOREIGN KEY (actor_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE settings (
  setting_key VARCHAR(120) PRIMARY KEY,
  setting_value TEXT NULL,
  value_type ENUM('STRING','INTEGER','BOOLEAN','JSON') NOT NULL DEFAULT 'STRING',
  is_public TINYINT(1) NOT NULL DEFAULT 0,
  description_ar VARCHAR(500) NULL,
  updated_by_user_id BIGINT UNSIGNED NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_settings_updated_by FOREIGN KEY (updated_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

INSERT INTO roles (id, code, name_ar, name_en, description) VALUES
(1,'SYSTEM_ADMIN','مدير النظام','System Administrator','إدارة كاملة للنظام والإعدادات'),
(2,'SUPPORT_MANAGER','مشرف الدعم','Support Manager','إدارة الطوابير والإسناد والتقارير'),
(3,'SUPPORT_AGENT','فني الدعم','Support Agent','تنفيذ الطلبات المسندة'),
(4,'INTERNAL_USER','موظف','Internal User','إنشاء ومتابعة الطلبات الشخصية'),
(5,'CLIENT_ADMIN','مدير عميل','Client Administrator','إدارة مستخدمي وطلبات شركته'),
(6,'CLIENT_USER','مستخدم عميل','Client User','إنشاء ومتابعة طلبات الشركة'),
(7,'PROVIDER_MANAGER','مدير مزود خدمة','Provider Manager','متابعة الأعمال المسندة للمزود'),
(8,'PROVIDER_TECHNICIAN','فني مزود خدمة','Provider Technician','تحديث الأعمال الخارجية'),
(9,'AUDITOR','مدقق','Auditor','وصول للقراءة والتدقيق');

INSERT INTO permissions (code, name_ar, module) VALUES
('dashboard.view','عرض لوحة التحكم','dashboard'),
('tickets.create','إنشاء الطلبات','tickets'),
('tickets.view_own','عرض الطلبات الشخصية','tickets'),
('tickets.view_all','عرض جميع الطلبات','tickets'),
('tickets.update','تحديث الطلبات','tickets'),
('tickets.assign','إسناد الطلبات','tickets'),
('tickets.internal_notes','إضافة الملاحظات الداخلية','tickets'),
('tickets.close','إغلاق الطلبات','tickets'),
('devices.view','عرض الأجهزة','devices'),
('devices.manage','إدارة الأجهزة','devices'),
('users.view','عرض المستخدمين','users'),
('users.manage','إدارة المستخدمين','users'),
('reports.view','عرض التقارير','reports'),
('reports.export','تصدير التقارير','reports'),
('settings.manage','إدارة الإعدادات','settings'),
('audit.view','عرض سجل التدقيق','audit');

INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions;

INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions WHERE code IN
('dashboard.view','tickets.create','tickets.view_all','tickets.update','tickets.assign','tickets.internal_notes','tickets.close','devices.view','devices.manage','users.view','reports.view','reports.export','audit.view');

INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions WHERE code IN
('dashboard.view','tickets.create','tickets.view_all','tickets.update','tickets.internal_notes','tickets.close','devices.view');

INSERT INTO role_permissions (role_id, permission_id)
SELECT 4, id FROM permissions WHERE code IN ('dashboard.view','tickets.create','tickets.view_own');

INSERT INTO role_permissions (role_id, permission_id)
SELECT 9, id FROM permissions WHERE code IN ('dashboard.view','tickets.view_all','devices.view','users.view','reports.view','reports.export','audit.view');

INSERT INTO service_provider_types (code, name_ar, name_en) VALUES
('INTERNET','مزود إنترنت','Internet Provider'),
('PRINTER','صيانة طابعات','Printer Maintenance'),
('ELECTRICAL','أعمال كهربائية','Electrical Services'),
('FACILITY','صيانة مرافق','Facility Maintenance'),
('GENERAL','مزود عام','General Provider');

INSERT INTO departments (company_id, code, name_ar, name_en) VALUES
(NULL,'IT','تقنية المعلومات','Information Technology'),
(NULL,'HR','الموارد البشرية','Human Resources'),
(NULL,'FIN','المالية','Finance'),
(NULL,'OPS','العمليات','Operations'),
(NULL,'ADMIN','الإدارة','Administration');

INSERT INTO locations (company_id, code, name_ar, name_en, location_type) VALUES
(NULL,'HQ','المقر الرئيسي','Head Office','OFFICE');

INSERT INTO device_types (code, name_ar, name_en) VALUES
('DESKTOP','جهاز مكتبي','Desktop'),
('LAPTOP','جهاز محمول','Laptop'),
('PRINTER','طابعة','Printer'),
('MONITOR','شاشة','Monitor'),
('ROUTER','راوتر','Router'),
('SWITCH','مبدّل شبكة','Network Switch'),
('ACCESS_POINT','نقطة وصول','Access Point'),
('PHONE','هاتف','Phone'),
('TABLET','جهاز لوحي','Tablet'),
('UPS','مزود طاقة احتياطي','UPS'),
('OTHER','جهاز آخر','Other');

INSERT INTO device_statuses (code, name_ar, name_en, is_assignable, sort_order) VALUES
('AVAILABLE','متاح','Available',1,10),
('ASSIGNED','مُسند','Assigned',0,20),
('ACTIVE','نشط','Active',0,30),
('IN_REPAIR','قيد الصيانة','In Repair',0,40),
('IN_STORAGE','في المخزن','In Storage',1,50),
('LOST','مفقود','Lost',0,60),
('RETIRED','متقاعد','Retired',0,70),
('DISPOSED','تم التخلص منه','Disposed',0,80);

INSERT INTO ticket_priorities (id, code, name_ar, name_en, color, first_response_minutes, resolution_minutes, sort_order) VALUES
(1,'LOW','منخفضة','Low','#9198A3',480,4320,40),
(2,'MEDIUM','متوسطة','Medium','#5CA9FF',240,1440,30),
(3,'HIGH','عالية','High','#FF9D4D',60,480,20),
(4,'CRITICAL','حرجة','Critical','#FF6472',15,120,10);

INSERT INTO ticket_statuses (id, code, name_ar, name_en, color, is_open, pauses_sla, sort_order) VALUES
(1,'NEW','جديدة','New','#5CA9FF',1,0,10),
(2,'TRIAGED','تم الفرز','Triaged','#A879FF',1,0,20),
(3,'ASSIGNED','مُسندة','Assigned','#FFD978',1,0,30),
(4,'IN_PROGRESS','قيد العمل','In Progress','#E8B84E',1,0,40),
(5,'PENDING_REQUESTER','بانتظار مقدم الطلب','Pending Requester','#9198A3',1,1,50),
(6,'PENDING_INTERNAL','بانتظار جهة داخلية','Pending Internal','#9198A3',1,1,60),
(7,'PENDING_PROVIDER','بانتظار المزود','Pending Provider','#9198A3',1,1,70),
(8,'PROVIDER_ON_SITE','المزود في الموقع','Provider On Site','#5CA9FF',1,0,80),
(9,'RESOLVED','تم الحل','Resolved','#43D17A',0,0,90),
(10,'CLOSED','مغلقة','Closed','#59616C',0,0,100),
(11,'CANCELLED','ملغاة','Cancelled','#FF6472',0,0,110);

INSERT INTO ticket_categories (id, parent_id, code, name_ar, name_en, icon, color, sort_order) VALUES
(1,NULL,'IT','تقنية المعلومات','Information Technology','cpu','#E8B84E',10),
(2,NULL,'FACILITIES','الخدمات والمرافق','Facilities','building','#5CA9FF',20),
(3,1,'COMPUTER','الكمبيوتر واللابتوب','Computer and Laptop','monitor','#E8B84E',30),
(4,1,'INTERNET','الإنترنت','Internet','wifi','#5CA9FF',40),
(5,1,'NETWORK','الشبكة الداخلية','Network','network','#5CA9FF',50),
(6,1,'EMAIL','البريد الإلكتروني','Email','mail','#A879FF',60),
(7,1,'PRINTER','الطابعة والتعريف','Printer and Driver','printer','#FF9D4D',70),
(8,1,'NEW_DEVICE','تجهيز جهاز جديد','New Device Setup','laptop','#43D17A',80),
(9,1,'NEW_ACCOUNT','إنشاء إيميل أو مستخدم','New Account','user-plus','#43D17A',90),
(10,1,'ACCESS','الصلاحيات وكلمة المرور','Access and Password','lock','#A879FF',100),
(11,1,'SOFTWARE','البرامج والتثبيت','Software Installation','package','#E8B84E',110),
(12,2,'ELECTRICAL','الكهرباء','Electrical','bolt','#FF9D4D',120),
(13,2,'AIR_CONDITIONING','التكييف','Air Conditioning','snow','#5CA9FF',130),
(14,2,'PLUMBING','السباكة','Plumbing','droplet','#5CA9FF',140),
(15,2,'GENERAL_INTERNAL','طلب داخلي عام','General Internal Request','clipboard','#9198A3',150);

INSERT INTO checklist_templates (id, code, name_ar, name_en, ticket_kind) VALUES
(1,'ONBOARDING_DEFAULT','قائمة تجهيز موظف جديد','Default Onboarding','ONBOARDING'),
(2,'OFFBOARDING_DEFAULT','قائمة إنهاء خدمات موظف','Default Offboarding','OFFBOARDING'),
(3,'NEW_DEVICE_DEFAULT','قائمة تجهيز جهاز جديد','New Device Setup','SERVICE_REQUEST');

INSERT INTO checklist_template_items (template_id, title_ar, title_en, sort_order, is_required) VALUES
(1,'اعتماد بيانات الموظف وتاريخ المباشرة','Confirm employee data and start date',10,1),
(1,'إنشاء حساب المستخدم','Create user account',20,1),
(1,'إنشاء البريد الإلكتروني','Create email account',30,1),
(1,'تجهيز الجهاز وتحديثه','Prepare and update device',40,1),
(1,'تثبيت البرامج المطلوبة','Install required software',50,1),
(1,'تعريف الطابعة وربط الشبكة','Configure printer and network',60,0),
(1,'منح الصلاحيات المعتمدة','Grant approved access',70,1),
(1,'تسليم الجهاز وتأكيد الدخول','Handover and verify access',80,1),
(2,'تأكيد آخر يوم عمل','Confirm final working day',10,1),
(2,'تعطيل حساب المستخدم','Disable user account',20,1),
(2,'معالجة البريد حسب قرار الإدارة','Handle mailbox per management decision',30,1),
(2,'سحب الجهاز والملحقات','Collect device and accessories',40,1),
(2,'إلغاء الصلاحيات والجلسات','Revoke access and sessions',50,1),
(2,'تحديث سجل الجهاز والمستخدم','Update device and user records',60,1),
(2,'توثيق اكتمال الإجراء','Document completion',70,1),
(3,'تسجيل رقم الأصل والرقم التسلسلي','Record asset and serial numbers',10,1),
(3,'تحديث نظام التشغيل والتعريفات','Update OS and drivers',20,1),
(3,'تثبيت الحماية والبرامج الأساسية','Install security and base software',30,1),
(3,'ربط الشبكة والطابعة','Configure network and printer',40,0),
(3,'اختبار الجهاز وتوثيق التسليم','Test and document handover',50,1);

INSERT INTO custom_fields (category_id, ticket_kind, code, label_ar, label_en, field_type, sort_order, is_required, is_sensitive) VALUES
(8,'SERVICE_REQUEST','new_device_employee','الموظف المستلم','Receiving employee','USER',10,1,0),
(9,'SERVICE_REQUEST','requested_email','البريد المطلوب','Requested email','TEXT',10,1,1),
(12,'GENERAL_REQUEST','electrical_risk','هل يوجد خطر مباشر؟','Immediate risk','CHECKBOX',10,1,0),
(NULL,'ONBOARDING','employee_start_date','تاريخ مباشرة الموظف','Employee start date','DATE',10,1,1),
(NULL,'OFFBOARDING','employee_last_day','آخر يوم عمل','Employee last day','DATE',10,1,1);

INSERT INTO settings (setting_key, setting_value, value_type, is_public, description_ar) VALUES
('app.name','بوابة تقنية المعلومات','STRING',1,'اسم النظام'),
('ticket.number_prefix','IT','STRING',0,'بادئة رقم الطلب'),
('ticket.default_priority','MEDIUM','STRING',0,'الأولوية الافتراضية'),
('attachments.max_mb','10','INTEGER',0,'أقصى حجم للمرفق بالميجابايت'),
('security.login_max_attempts','5','INTEGER',0,'عدد المحاولات قبل القفل'),
('security.lock_minutes','15','INTEGER',0,'مدة القفل المؤقت بالدقائق'),
('notifications.email_enabled','false','BOOLEAN',0,'تفعيل إشعارات البريد');

CREATE VIEW vw_open_ticket_summary AS
SELECT
  t.id,
  t.ticket_number,
  t.title,
  t.ticket_kind,
  c.name_ar AS category_name,
  p.code AS priority_code,
  p.name_ar AS priority_name,
  s.code AS status_code,
  s.name_ar AS status_name,
  CONCAT(r.first_name, ' ', r.last_name) AS requester_name,
  CONCAT(a.first_name, ' ', a.last_name) AS assignee_name,
  t.due_at,
  t.created_at,
  t.updated_at
FROM tickets t
JOIN ticket_categories c ON c.id = t.category_id
JOIN ticket_priorities p ON p.id = t.priority_id
JOIN ticket_statuses s ON s.id = t.status_id
JOIN users r ON r.id = t.requester_user_id
LEFT JOIN users a ON a.id = t.assigned_user_id
WHERE s.is_open = 1;

SET FOREIGN_KEY_CHECKS = 1;
