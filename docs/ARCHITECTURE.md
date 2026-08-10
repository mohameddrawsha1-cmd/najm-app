# Architecture and Technical Notes

## Baseline

- PHP 8.2 modular monolith
- MySQL 8, InnoDB, utf8mb4
- Arabic-first RTL interface
- Server-rendered MVC with progressive JavaScript
- UTC database timestamps and configurable display timezone
- Single public entry point at public/index.php

## Request flow

1. Apache or the PHP development server sends the request to public/index.php.
2. Bootstrap loads .env, autoloading, timezone, and the secure session.
3. routes/web.php maps the request to a controller.
4. The router verifies CSRF for every non-GET request.
5. Controllers enforce authentication and roles, validate input, and call repositories.
6. Repositories use prepared PDO statements and database transactions.
7. Views escape output through e() and render inside an RTL layout.
8. Important writes append audit and history rows.

## Modules

| Module | Main tables |
|---|---|
| Identity and access | users, roles, permissions, role_permissions, login_attempts, password_reset_tokens |
| Organization | clients, companies, departments, locations, teams, team_members |
| Assets | device_types, device_statuses, devices, device_history |
| Tickets | tickets, ticket_categories, ticket_statuses, ticket_priorities, ticket_messages, ticket_attachments, ticket_status_history |
| Assignment | ticket_assignments, service_provider_types, service_providers, provider_users |
| Structured work | checklist_templates, checklist_template_items, ticket_checklist_items, custom_fields, custom_field_options, ticket_custom_field_values |
| Operations | notifications, audit_logs, settings |

## Security boundaries

- Authorization is enforced server-side; hidden navigation items are only a usability layer.
- Ordinary users can see only tickets they requested or created.
- Internal notes are removed from requester queries.
- Assignment and status administration require support roles.
- Sensitive onboarding and offboarding tickets are flagged for stricter policies.
- Prepared statements, output encoding, CSRF tokens, secure password hashing, session rotation, and login throttling are enabled.
- Attachments are designed for private storage outside public. Upload endpoints must validate MIME, size, extension, ownership, and authorization before launch.

## Extension points

- Email notifications can consume the notifications table through a scheduled worker.
- Client portals can apply company_id scopes already present in users, locations, devices, and tickets.
- Provider login can apply provider_id scopes and current assignment checks.
- Approval flows can be added as append-only records without changing ticket history.
- REST endpoints can use a separate API router with token scopes and the same authorization policies.

## Deployment checklist

- Import the schema into a new database.
- Create a restricted database user.
- Create the first administrator with the CLI script.
- Configure APP_URL, timezone, secure cookies, and HTTPS.
- Set the web root to public.
- Make storage/logs and storage/uploads writable but not executable.
- Run syntax and smoke tests.
- Test backup and restore.
- Test role access and real onboarding, offboarding, printer, email, internet, and electricity scenarios.
