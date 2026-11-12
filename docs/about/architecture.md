# Architecture and Data Policy

This page defines the data contract for LesliAudit. It separates operational
analytics from durable activity auditing so each workload can use appropriate
reliability, retention, and storage rules.

## Visible Domains

The authenticated interface exposes five reports with deliberately narrow
responsibilities:

| Report | Question answered | Main records | Audit evidence? |
| --- | --- | --- | --- |
| Users | Who belongs to this account and when was their retained activity observed? | Core users and reduced `UserJournal` working hours | No |
| Analytics | How are authenticated users using the application in aggregate? | `AccountRequest`, `AccountDevice`, and aggregate journal data | No |
| Traffic | How often were mapped resources requested through Cloudflare? | `TrafficRollup` and `TrafficBreakdown` | No |
| Requests | Which authenticated application endpoints were requested, subject to the viewer's role scope? | `UserRequest` | No |
| Logs | Which explicit business or security operations were emitted? | `UserLog` and `AccountLog` | Yes |

These five reports use three storage and reliability policies:

| Policy domain | Visible reports | Write behavior |
| --- | --- | --- |
| Authenticated usage analytics | Users, Analytics, and Requests | Synchronous aggregate counters and optional journals |
| Provider traffic | Traffic | Idempotent replacement of daily aggregate snapshots |
| Activity audit | Logs | Durable, append-only, and written synchronously with the audited operation |

Request analytics must not be presented as an audit trail. Activity audit must
not be populated automatically from every controller request; the business
operation that understands the event must emit it explicitly.

User journals belong to request analytics. They provide detailed operational
timing but are not permanent audit evidence.

Traffic is not captured by the authenticated controller
callback. A CDN or browser telemetry provider observes the traffic, and the
host imports aggregate snapshots through `LesliAudit::TrafficSnapshotImporter`.
Traffic is reporting data supplied by an external provider. It is eventually
consistent, may be sampled or adjusted, and is never evidence that a business
operation succeeded.

## Navigation and Authorization

The authenticated interface uses this fixed order: **Users · Analytics ·
Traffic · Requests · Logs**. Each item is one word and maps directly to a
standard Rails resource: `users#index`, `analytics#index`, `traffic#index`,
`requests#index`, and `logs#index`. Log detail uses `logs#show`.

LesliShield grants access through those controller resources and role
permissions. LesliAudit does not maintain a second navigation authorization
system. Each navigation item uses its resource helper, so the shared
`navigation_item` helper marks only the current route as active. Because Rails
treats `traffic` as uncountable, its index helper is `traffic_index_path`; the
public URL remains `/audit/traffic`. No legacy route aliases are retained.

## Storage Semantics

Request capture can produce two different representations:

1. `UserJournal` stores one individual event for the captured request when
   both analytics and journal capture are enabled.
2. `UserRequest` and `AccountRequest` store grouped counters. A matching event
   increments `request_count` instead of preserving another request timestamp.

`AccountDevice` is a grouped successful-login counter by normalized agent
category, not a count of distinct physical devices or people. It is written
only when the authentication flow explicitly calls `log_devices`.

`TrafficRollup` maps a hostname and path such as `example.com/ldonis` to an opaque
host-owned resource identity and stores one daily total. `TrafficBreakdown`
stores optional country, device, browser, operating-system, or referrer
distributions. Imports replace the complete snapshot for a day; they never
increment an existing provider total.

`UserLog` and `AccountLog` are separate append-only activity records created
only when application code explicitly emits a meaningful operation. They are
the only records in this engine intended as audit evidence. See
[Database](/engines/audit/about/database#choosing-the-correct-record) for the
complete table-by-table comparison.

The Logs interface preserves that distinction. `UserLog` is a user history;
`AccountLog` is a tenant history. LesliShield role permissions decide whether
the Logs controller is available. An authorized role can inspect both histories
for its account, and every list and detail query remains anchored to that
current Audit account.

## Reliability

Request analytics is written synchronously by the controller callback. Database
errors follow the host application's normal controller error handling; there
is no analytics queue or background retry path.

Activity audit is **fail-closed** for operations declared auditable. The event
must be written in the same transaction boundary as the business change. If
the audit event cannot be persisted, that change must not commit. This avoids
reporting a successful operation without its required audit evidence.

Traffic is eventually consistent. Provider collection and
host scheduling remain outside the engine, and repeating the same import is
safe. A provider outage must not affect delivery of the public resource.

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

The account-device counters measure **successful logins**, not unique people or
unique devices. Reports and interface labels must describe login agent
distribution instead of anonymous traffic counts.

The `/analytics` route reports authenticated application usage. A future
unique-session metric must use a separate table
or aggregation key; it must not reinterpret historical request counters as
people.

No persistent browser fingerprint is part of the default design. A future
unique-person feature requires a separate privacy review and an explicit
retention policy.

Traffic rollups intentionally retain the provider concepts
`page_views` and `visits`. A visit is not presented as a unique person unless
the selected provider supplies a metric with that explicit contract.

## Retention Defaults

Retention is based on the data's purpose:

| Data | Default retention | Reason |
| --- | --- | --- |
| Authenticated requests, journals, and successful-login device aggregates | 400 days | Supports current-year and year-over-year reporting under one Analytics policy |
| Traffic rollups and breakdowns | 400 days | Supports resource trends without retaining individual request events |
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

Traffic stores only provider aggregates. It does not store
raw IP addresses, user-agent strings, cookies, browser fingerprints, or an
event row for each anonymous request.

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
    analytics_retention_days: 400,
    traffic_retention_days: 400,
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
All authenticated analytics, including retained and transient journals, use
the analytics period. Imported snapshots use the traffic period. The operation
is idempotent and reports the number deleted from every table.

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

The controller integration delegates authenticated request capture directly to
`LesliAudit::LoggerInterface#log_requests`. `enable_analytics` is the master
switch: when enabled, the logger upserts the account request counter and, when
a session is available, the user request counter. It also creates an individual
request journal when `enable_journals` is enabled. Disabling analytics stops
all request counters, journals, and successful-login device aggregates.

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

LesliAudit includes the standard Cloudflare Traffic adapter. Its client queries
Cloudflare, its converter builds normalized snapshots, and the importer writes
those snapshots to the engine tables. The host supplies deployment-specific
configuration and scheduling. Provider credentials remain in encrypted
credentials or the deployment secret manager and are never passed to a public
page.

Until the first production deployment, schema hardening may be consolidated in
the existing `v1.0` migrations so a fresh installation starts from the target
schema. After a migration has reached production, further schema changes must
use new migrations and remain backward compatible.

See [Database](/engines/audit/about/database) for the current tables and
[Migration Versioning](/engines/lesli/database/versioning) for the migration
rules.
