# Architecture and Data Policy

This page defines the data contract for LesliAudit. It separates operational
analytics from durable activity auditing so each workload can use appropriate
reliability, retention, and storage rules.

## Data Domains

LesliAudit owns two related but distinct domains:

| Domain | Purpose | Examples | Write behavior |
| --- | --- | --- | --- |
| Request analytics | Measure application traffic without reconstructing individual business actions | Requests by controller, daily user activity, successful-login agent distribution | Synchronous aggregate counters and optional journals |
| Activity audit | Preserve explicit business and security events | Record created, permission changed, session revoked, account initialized | Durable, append-only, and written synchronously with the audited operation |

Request analytics must not be presented as an audit trail. Activity audit must
not be populated automatically from every controller request; the business
operation that understands the event must emit it explicitly.

User journals belong to request analytics. They provide detailed operational
timing but are not permanent audit evidence.

## Storage Semantics

Request capture can produce two different representations:

1. `UserJournal` stores one individual event for the captured request when
   journal capture is enabled.
2. `UserRequest` and `AccountRequest` store grouped counters. A matching event
   increments `request_count` instead of preserving another request timestamp.

`AccountDevice` is a grouped successful-login counter by normalized agent
category, not a count of distinct physical devices or people. It is written
only when the authentication flow explicitly calls `log_devices`.

`UserLog` and `AccountLog` are separate append-only activity records created
only when application code explicitly emits a meaningful operation. They are
the only records in this engine intended as audit evidence. See
[Database](/engines/audit/about/database#choosing-the-correct-record) for the
complete table-by-table comparison.

## Reliability

Request analytics is written synchronously by the controller callback. Database
errors follow the host application's normal controller error handling; there
is no analytics queue or background retry path.

Activity audit is **fail-closed** for operations declared auditable. The event
must be written in the same transaction boundary as the business change. If
the audit event cannot be persisted, that change must not commit. This avoids
reporting a successful operation without its required audit evidence.

The generic request callback is therefore an analytics integration point, not
an activity-audit integration point.

## Authentication Sessions

LesliShield is optional: LesliAudit declares no runtime dependency on it.
Session identity is consequently an optional, opaque reference owned by the
authentication provider.

- Analytics may include a session reference when one is available.
- Activity events may exist without a session, for example system jobs.
- LesliAudit does not add a database foreign key to a LesliShield table.
- Audit models expose `session_id` as plain metadata and do not declare a
  LesliShield association.
- A session reference must never be treated as proof that its external record
  still exists.

This contract keeps LesliAudit installable without LesliShield and allows a
host application to use another authentication provider.

## Traffic Semantics

The account-device counters measure **successful logins**, not unique visitors
or unique devices. Reports and interface labels must describe login agent
distribution instead of request or visitor counts.

The `/visitors` route remains as a compatibility alias for `/analytics`. A
future unique-session metric must use a separate table
or aggregation key; it must not reinterpret historical request counters as
visitors.

No persistent browser fingerprint is part of the default design. A future
unique-visitor feature requires a separate privacy review and an explicit
retention policy.

## Retention Defaults

Retention is based on the data's purpose:

| Data | Default retention | Reason |
| --- | --- | --- |
| User journals | 90 days | High-volume diagnostic detail |
| Daily request, user, and successful-login device aggregates | 400 days | Supports current-year and year-over-year reporting |
| Activity audit events | No automatic deletion | Deletion depends on the host application's legal and compliance policy |

The host application may shorten these periods. Increasing them should be an
explicit capacity and privacy decision. Cleanup must run in bounded batches and
must be safe to retry.

Activity events are retained during normal soft deletion. A deliberate hard
purge of a tenant removes its LesliAudit data after any required export or legal
hold. If an individual actor is hard-deleted while the tenant remains, the
event is retained with an actor snapshot and a nullable user reference.

## Data Minimization

Request analytics stores normalized controller and action dimensions. The
successful-login device aggregate stores normalized platform, browser, and
device categories. Neither path stores raw user-agent strings, request bodies,
credentials, authorization headers, cookies, or IP addresses by default.

Activity-event metadata uses an allowlist. Secrets, authentication tokens, and
unfiltered request parameters must never be written. Subject identifiers and
actor snapshots should contain only the information required to understand the
event.

## Configuration

Write switches and retention periods are available through the Audit
configuration namespace:

```ruby
Lesli.configure do |config|
  config.audit = config.audit.merge(
    enable_logs: true,
    enable_journals: true,
    enable_analytics: true,
    journal_retention_days: 90,
    analytics_retention_days: 400,
    audit_retention_days: nil
  )
end
```

All these settings are active. A retention value must be a positive integer of
days or `nil`; `nil` makes retention cleanup skip that data class. The
default `audit_retention_days: nil` therefore preserves activity events until
the host application explicitly adopts a legal and operational retention
period.

## Retention Cleanup

`LesliAudit::RetentionCleanup` removes expired records using bounded primary-key
batches. Date-based analytics delete rows whose `date` is older than their
cutoff; activity events use `created_at`. Rows exactly on the cutoff are kept.
Unprocessed journals are never deleted. Retained journals use the journal
period, while transient journals use the analytics period. The operation is
idempotent and reports the number deleted from every table.

The engine exposes `LesliAudit::RetentionCleanupJob` for the host scheduler and
the following manual task:

```shell
bin/rails lesli_audit:retention:cleanup
```

LesliAudit does not choose a schedule because job backends and maintenance
windows belong to the host application. Running cleanup once per day is the
recommended default. A host should verify export and legal-hold requirements
before enabling activity-event retention.

## Implementation Boundary

The controller integration delegates request traffic directly to
`LesliAudit::LoggerInterface#log_requests`. When analytics is enabled, it
upserts the account request counter and, when a session is available, the user
request counter. When journals are enabled, it creates an individual request
journal. `enable_analytics` and `enable_journals` are evaluated independently.

Device aggregation is deliberately outside this request pipeline.
`LesliAudit::LoggerInterface#log_devices` is called by LesliShield only after a
successful login and increments one normalized agent counter for that login.

Activity auditing uses `LesliAudit::ActivityAudit`, a deliberately small entry
point that accepts only allowlisted event fields. It resolves the engine account,
normalizes identifiers, snapshots the actor UID, and persists through `create!`.
It does not rescue persistence errors: callers must invoke it inside the same
database transaction as the business change when both must succeed together.

`Lesli::Account#log` and `Lesli::User#log` delegate to this entry point when the
optional Audit engine is installed. With `enable_logs: false`, both calls are
intentional no-ops. Persisted account and user activity events are read-only;
an event outcome is represented by a new event, never by editing the original.
A core account's normal soft deletion keeps its audit history. A deliberate
hard deletion cascades through database foreign keys to the Audit account and
its data, without requiring the core model to own engine lifecycle callbacks.

Until the first production deployment, schema hardening may be consolidated in
the existing `v1.0` migrations so a fresh installation starts from the target
schema. After a migration has reached production, further schema changes must
use new migrations and remain backward compatible.

See [Database](/engines/audit/about/database) for the current tables and
[Migration Versioning](/engines/lesli/database/versioning) for the migration
rules.
