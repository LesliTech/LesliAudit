# Architecture and Data Policy

This page defines the target contract for LesliAudit. It separates operational
analytics from durable activity auditing so each workload can use appropriate
reliability, retention, and storage rules.

## Data Domains

LesliAudit owns two related but distinct domains:

| Domain | Purpose | Examples | Write behavior |
| --- | --- | --- | --- |
| Request analytics | Measure application traffic without reconstructing individual business actions | Requests by controller, daily user activity, browser and device distribution | Best effort, aggregated, and safe to process asynchronously |
| Activity audit | Preserve explicit business and security events | Record created, permission changed, session revoked, account initialized | Durable, append-only, and written synchronously with the audited operation |

Request analytics must not be presented as an audit trail. Activity audit must
not be populated automatically from every controller request; the business
operation that understands the event must emit it explicitly.

User journals belong to request analytics. They provide detailed operational
timing but are not permanent audit evidence.

## Reliability

Analytics is **fail-open**. A parsing, queue, or analytics database error must
be reported through Rails error reporting, but it must not change an otherwise
successful application response. Analytics events must be idempotent so a job
can be retried without increasing a counter twice.

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
- Model associations with LesliShield must be conditional and optional.
- A session reference must never be treated as proof that its external record
  still exists.

This contract keeps LesliAudit installable without LesliShield and allows a
host application to use another authentication provider.

## Traffic Semantics

The existing account-device counters measure **requests**, not unique visitors
or unique devices. Reports and interface labels must use terms such as
"traffic", "requests by device", and "request analytics".

The current `/visitors` route may remain as a compatibility alias while the
interface is renamed. A future unique-session metric must use a separate table
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
| Daily request, user, and device aggregates | 400 days | Supports current-year and year-over-year reporting |
| Activity audit events | No automatic deletion | Deletion depends on the host application's legal and compliance policy |

The host application may shorten these periods. Increasing them should be an
explicit capacity and privacy decision. Cleanup must run in bounded batches and
must be safe to retry.

Activity events are retained during normal soft deletion. A deliberate hard
purge of a tenant removes its LesliAudit data after any required export or legal
hold. If an individual actor is hard-deleted while the tenant remains, the
event is retained with an actor snapshot and a nullable user reference.

## Data Minimization

Request analytics stores normalized controller, action, platform, browser, and
device categories. It does not store raw user-agent strings, request bodies,
credentials, authorization headers, cookies, or IP addresses by default.

Activity-event metadata uses an allowlist. Secrets, authentication tokens, and
unfiltered request parameters must never be written. Subject identifiers and
actor snapshots should contain only the information required to understand the
event.

## Target Configuration

Later implementation phases will expose these defaults through the Audit
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

`nil` means that LesliAudit does not automatically purge activity events. These
keys describe the target contract and must not be treated as active until their
cleanup and configuration implementation is released.

## Implementation Boundary

The controller integration delegates request traffic to
`LesliAudit::RequestAnalytics`. Each aggregate or journal write is isolated and
reported through `Rails.error`, so an analytics failure does not alter the
application response. The `enable_analytics` and `enable_journals` settings are
evaluated independently.

Request analytics remains synchronous until its delivery mechanism has a
durable idempotency key. Moving counter increments directly to a retryable job
would risk counting the same request more than once.

Activity auditing must use a separate `ActivityAudit` entry point. It may share
event normalization and account resolution with request analytics, but it must
not share failure or retention behavior.

Until the first production deployment, schema hardening may be consolidated in
the existing `v1.0` migrations so a fresh installation starts from the target
schema. After a migration has reached production, further schema changes must
use new migrations and remain backward compatible.

See [Database](/engines/audit/about/database) for the current tables and
[Migration Versioning](/engines/lesli/database/versioning) for the migration
rules.
