# Database

LesliAudit uses collection code `05` and engine code `01`. Its migrations live under `db/migrate/v1.0` and are loaded into the host application's migration set.

| Migration code | Table | Responsibility |
| --- | --- | --- |
| `05.01.00.01.10` | `lesli_audit_accounts` | Engine state for a Lesli account |
| `05.01.11.01.10` | `lesli_audit_account_logs` | Account-level activity records |
| `05.01.11.02.10` | `lesli_audit_account_devices` | Aggregated browser, platform, and device observations |
| `05.01.11.03.10` | `lesli_audit_account_requests` | Account request counts by controller and action |
| `05.01.12.01.10` | `lesli_audit_user_logs` | User-specific activity records |
| `05.01.12.02.10` | `lesli_audit_user_journals` | Durable request inbox and retained user journal data |
| `05.01.12.03.10` | `lesli_audit_user_requests` | User request analytics |

## Choosing the Correct Record

The similarly named tables do not contain interchangeable data:

| Model and table | Record granularity | Primary use | Audit evidence? |
| --- | --- | --- | --- |
| `AccountLog` / `lesli_audit_account_logs` | One explicitly emitted tenant-level business or security event | Account lifecycle and operations whose actor may be a user | Yes |
| `UserLog` / `lesli_audit_user_logs` | One explicitly emitted user activity event | A user's business or security history | Yes |
| `AccountRequest` / `lesli_audit_account_requests` | One counter per tenant, date, controller, and action | Traffic totals and controller trends | No |
| `UserRequest` / `lesli_audit_user_requests` | One counter per tenant, user, optional session, date, controller, and action | Per-user request totals | No |
| `UserJournal` / `lesli_audit_user_journals` | One normalized row per captured HTTP request | Durable analytics delivery and, when enabled, detailed user timing/history | No |
| `AccountDevice` / `lesli_audit_account_devices` | One counter per tenant, date, platform, browser, and device category | Request distribution by normalized agent category | No |

### User requests versus user journals

`UserRequest` is an **aggregate counter**. Repeated matching requests increase
`request_count`; the row is intended for totals and grouped reports. It does
not preserve the time of every individual request and must not be used to prove
that a business operation occurred.

`UserJournal` is an **individual request event** and the durable inbox for the
analytics pipeline. Its tenant-scoped `event_uid` deduplicates capture,
`processed_at` records successful aggregation, and `created_at` identifies when
the request was captured. When `enable_journals` is true, normalized request,
user, session, and agent dimensions remain available for operational history
and working-hours reports. When it is false, those dimensions are scrubbed
after processing and only the minimum deduplication lifecycle data remains.

In short:

- query `user_requests` to answer **how many matching requests** a user made;
- query retained `user_journals` to answer **when individual requests** were
  captured;
- query `user_logs` to answer **which explicit auditable operations** the user
  performed.

Neither request table replaces `UserLog`. A controller request can finish
without representing a business change, while one business operation may also
emit multiple outcome events.

The accounts table uses `create_table_lesli_shared_account_10(:lesli_audit)` and adds a unique index over `account_id`, so each core account has exactly one audit account. Request and device tables use a dedicated `date` column for their aggregation bucket and normal Rails timestamps for record lifecycle metadata.

The engine owns its foreign-key lifecycle rules. Core account soft deletion
keeps every physical row intact. Hard deletion cascades from the core account
to its Audit account and then to all tenant audit data. A hard-deleted user
cascades aggregate request rows and nullifies actor references on journals and
activity events, preserving their immutable identity snapshots.

LesliAudit installs the `audit` association on `Lesli::Account` through
`LesliAudit::AccountAssociations`. Every Audit-owned record then belongs to
`LesliAudit::Account`, while user-owned records also reference `Lesli::User`.
Destroying an Audit account is a deliberate hard purge and deletes its
dependent Audit records.

The initial schema enforces required tenant and dimension columns,
nonnegative 64-bit counters, and tenant-first unique indexes. Logger upserts
identify these constraints by index name so column order can continue to
support account-scoped access. Session identifiers remain nullable opaque
references and do not create a database dependency on LesliShield.

Request inbox rows use a tenant-scoped unique `event_uid`. Normalized request
and device dimensions are processed asynchronously, and `processed_at` makes
job retries idempotent. Pending rows are excluded from retention cleanup. When
journals are disabled, successfully processed rows are scrubbed down to their
event identity and lifecycle fields.

Account and user activity logs require an `operation`, use text for their
human-readable description, and index account plus creation time for tenant
history queries. User histories additionally index user plus creation time.
`actor_uid` is an immutable identity snapshot: the `user_id` foreign key may be
set to null when a user is hard-deleted, while the event and actor snapshot are
retained. Persisted activity rows are append-only at the model layer; status
changes such as attempted, failed, and succeeded are separate rows.

Run schema operations through the host application:

```shell
bin/rails lesli:db:prepare
bin/rails db:migrate:status
```

Run configured retention cleanup manually with:

```shell
bin/rails lesli_audit:retention:cleanup
```

Re-enqueue request events left pending by a queue outage with:

```shell
bin/rails lesli_audit:analytics:retry_pending
```

The retention operation is available to host schedulers through
`LesliAudit::RetentionCleanupJob`. Cleanup uses the `date` indexes for journals
and analytics and the `created_at` indexes for activity histories, deleting in
bounded batches. Activity histories are skipped while
`audit_retention_days` is `nil`.

Audit data can grow quickly. New queries should remain account-scoped and be supported by indexes matching their filters and grouping columns.

The retention and reliability rules differ between aggregated analytics,
short-lived journals, and durable activity events. See
[Architecture and Data Policy](/engines/audit/about/architecture) before
changing a table or adding a new event source.

See [Database Architecture](/engines/lesli/database/structure) and [Migration Versioning](/engines/lesli/database/versioning) for shared rules.
