# Database

LesliAudit uses collection code `05` and engine code `01`. Its migrations live under `db/migrate/v1.0` and are loaded into the host application's migration set.

| Migration code | Table | Responsibility |
| --- | --- | --- |
| `05.01.00.01.10` | `lesli_audit_accounts` | Engine state for a Lesli account |
| `05.01.11.01.10` | `lesli_audit_account_logs` | Account-level activity records |
| `05.01.11.02.10` | `lesli_audit_account_devices` | Aggregated browser, platform, and device observations from successful logins |
| `05.01.11.03.10` | `lesli_audit_account_requests` | Account request counts by controller and action |
| `05.01.12.01.10` | `lesli_audit_user_logs` | User-specific activity records |
| `05.01.12.02.10` | `lesli_audit_user_journals` | Individual user request journals |
| `05.01.12.03.10` | `lesli_audit_user_requests` | User request analytics |
| `05.01.13.01.10` | `lesli_audit_traffic_rollups` | Daily page-view and visit snapshots imported from a provider |
| `05.01.13.02.10` | `lesli_audit_traffic_breakdowns` | Optional dimensions belonging to a daily traffic rollup |
| `05.01.13.03.10` | `lesli_audit_cloudflare_traffic_syncs` | Cloudflare synchronization status by account, zone, and period |

## Complete Column Dictionary

Every table has an `id` primary key plus non-null `created_at` and `updated_at`
timestamps. The tables below list every additional column. “Audit account”
means `lesli_audit_accounts`; “core account” and “core user” mean
`lesli_accounts` and `lesli_users`.

### `lesli_audit_accounts`

| Column | Type | Meaning |
| --- | --- | --- |
| `account_id` | Foreign key | Required, unique core account. Hard deletion cascades to this row. |
| `name` | String | Optional engine-local account label. |
| `status` | Integer | Required engine account state; defaults to `0`. |
| `enabled_at` | Date-time | Optional time at which Audit was enabled. |
| `deleted_at` | Date-time | Soft-deletion marker used by the shared account model. |

### `lesli_audit_account_logs` and `lesli_audit_user_logs`

Both append-only event tables use the same event columns. Their distinction is
semantic: `AccountLog` is tenant history and `UserLog` is user-associated
history.

| Column | Type | Meaning |
| --- | --- | --- |
| `account_id` | Foreign key | Required Audit account; hard deletion cascades to the event. |
| `user_id` | Foreign key | Optional core user; hard user deletion nullifies the reference and preserves the event. |
| `engine` | String | Optional engine that emitted the event. |
| `source` | String | Optional emitting component or workflow. |
| `action` | String | Optional application action associated with the event. |
| `operation` | String | Required allowlisted business or security operation. |
| `description` | Text | Optional human-readable event description. |
| `session_id` | String | Optional opaque authentication-session reference; it has no Shield foreign key. |
| `actor_uid` | String | Immutable actor identity snapshot retained when `user_id` is nullified. |
| `subject_type` | String | Optional opaque subject type. LesliAudit does not constantize it. |
| `subject_id` | Big integer | Optional opaque subject identifier. |
| `details` | JSON | Explicit domain evidence; a required object defaulting to `{}`. |

### `lesli_audit_account_devices`

| Column | Type | Meaning |
| --- | --- | --- |
| `account_id` | Foreign key | Required Audit account; part of the tenant-first unique key. |
| `agent_platform` | String | Required normalized operating-system or platform category observed at successful login. |
| `agent_browser` | String | Required normalized browser category observed at successful login. |
| `agent_device` | String | Required normalized device category observed at successful login. |
| `agent_count` | Big integer | Required nonnegative successful-login count; defaults to `0`. |
| `date` | Date | Required daily aggregation bucket and retention date. |

The unique key is account, date, platform, browser, and device. This table does
not identify physical devices or unique people.

### `lesli_audit_account_requests`

| Column | Type | Meaning |
| --- | --- | --- |
| `account_id` | Foreign key | Required Audit account; part of the tenant-first unique key. |
| `request_controller` | String | Required normalized Rails controller. |
| `request_action` | String | Required normalized Rails action. |
| `request_count` | Big integer | Required nonnegative matching-request count; defaults to `0`. |
| `date` | Date | Required daily aggregation bucket and retention date. |

The unique key is account, date, controller, and action.

### `lesli_audit_user_journals`

| Column | Type | Meaning |
| --- | --- | --- |
| `account_id` | Foreign key | Required Audit account; scopes identity and access. |
| `user_id` | Foreign key | Optional core user; hard user deletion nullifies the reference. |
| `event_uid` | String | Required event identifier, unique within the Audit account. |
| `request_controller` | String | Optional normalized Rails controller. |
| `request_action` | String | Optional normalized Rails action. |
| `date` | Date | Required reporting and retention day. |
| `session_id` | String | Optional opaque authentication-session reference. |
| `agent_platform` | String | Optional normalized platform captured for the request. |
| `agent_browser` | String | Optional normalized browser captured for the request. |
| `agent_device` | String | Optional normalized device category captured for the request. |
| `retain` | Boolean | Required retention category; defaults to `true`. |

### `lesli_audit_user_requests`

| Column | Type | Meaning |
| --- | --- | --- |
| `account_id` | Foreign key | Required Audit account; scopes every report query. |
| `user_id` | Foreign key | Required core user; hard user deletion cascades to the aggregate. |
| `request_controller` | String | Required normalized Rails controller. |
| `request_action` | String | Required normalized Rails action. |
| `request_count` | Big integer | Required nonnegative matching-request count; defaults to `0`. |
| `date` | Date | Required daily aggregation bucket and retention date. |
| `session_id` | String | Optional opaque session dimension used by the aggregate key. |

The unique key is account, user, optional session, date, controller, and
action.

### `lesli_audit_traffic_rollups`

| Column | Type | Meaning |
| --- | --- | --- |
| `account_id` | Foreign key | Required Audit account; hard deletion cascades to the snapshot. |
| `provider` | String | Required normalized provider identifier, currently `cloudflare`. |
| `hostname` | String | Required normalized hostname without scheme, port, credentials, or trailing dot. |
| `path` | String | Required normalized path; query strings and fragments are removed. |
| `resource_type` | String | Required opaque host resource type. |
| `resource_id` | Big integer | Required positive opaque host resource identifier. |
| `date` | Date | Required provider reporting day. |
| `page_views` | Big integer | Required nonnegative provider request total stored under the Traffic UI contract. |
| `visits` | Big integer | Required nonnegative provider visit total. |
| `snapshot_at` | Date-time | Required snapshot version used to reject retries and out-of-order imports. |

The unique key is account, provider, hostname, path, and date. Resource queries
use the account, resource type, resource ID, and date index.

### `lesli_audit_traffic_breakdowns`

| Column | Type | Meaning |
| --- | --- | --- |
| `account_id` | Foreign key | Required Audit account; validated to match the parent rollup account. |
| `traffic_rollup_id` | Foreign key | Required parent snapshot; deletion cascades to the breakdown. |
| `dimension` | String | Required normalized `country`, `device`, `browser`, `operating_system`, or `referrer` dimension. |
| `value` | String | Required normalized value within the dimension. |
| `page_views` | Big integer | Required nonnegative attributed page-view count. |
| `visits` | Big integer | Required nonnegative attributed visit count. |

The unique key is account, rollup, dimension, and value. Provider totals and
breakdown totals may differ because providers can sample or suppress data.

### `lesli_audit_cloudflare_traffic_syncs`

| Column | Type | Meaning |
| --- | --- | --- |
| `account_id` | Foreign key | Required Audit account; hard deletion cascades to the synchronization history. |
| `zone_id` | String | Required Cloudflare zone used by the import. It is not a credential. |
| `period_start` | Date | First complete UTC day requested by the job. |
| `period_end` | Date | Last complete UTC day requested by the job. |
| `status` | String | Required `pending`, `running`, `succeeded`, or `failed` state. |
| `execution_id` | String | Temporary worker identifier that prevents an old retry from finishing a newer execution. |
| `snapshots_count` | Integer | Number of converted snapshots written by the successful execution. |
| `started_at` | Date-time | Time at which the worker acquired the synchronization row. |
| `finished_at` | Date-time | Time at which the worker succeeded or failed. |
| `last_synced_at` | Date-time | Time of the most recent successful execution; failures do not clear it. |
| `error_message` | Text | Most recent failure message, limited by the model before persistence. |

The unique key is Audit account, Cloudflare zone, start date, and end date.
The row lock prevents two workers from importing the exact same period at the
same time.

## Choosing the Correct Record

The similarly named tables do not contain interchangeable data:

| Model and table | Record granularity | Primary use | Audit evidence? |
| --- | --- | --- | --- |
| `AccountLog` / `lesli_audit_account_logs` | One explicitly emitted tenant-level business or security event | Account lifecycle and operations whose actor may be a user | Yes |
| `UserLog` / `lesli_audit_user_logs` | One explicitly emitted user activity event | A user's business or security history | Yes |
| `AccountRequest` / `lesli_audit_account_requests` | One counter per tenant, date, controller, and action | Authenticated request totals and controller trends | No |
| `UserRequest` / `lesli_audit_user_requests` | One counter per tenant, user, optional session, date, controller, and action | Per-user request totals | No |
| `UserJournal` / `lesli_audit_user_journals` | One normalized row per captured HTTP request | Detailed user timing and request history | No |
| `AccountDevice` / `lesli_audit_account_devices` | One counter per tenant, date, platform, browser, and device category | Successful-login distribution by normalized agent category | No |
| `TrafficRollup` / `lesli_audit_traffic_rollups` | One provider snapshot per tenant, hostname, path, and date | Public page views and visits attributed to a host resource | No |
| `TrafficBreakdown` / `lesli_audit_traffic_breakdowns` | One value within a rollup dimension | Country, device, browser, operating-system, and referrer distributions | No |
| `CloudflareTrafficSync` / `lesli_audit_cloudflare_traffic_syncs` | One synchronization state per tenant, zone, and requested period | Job coordination, errors, and freshness shown by Traffic | No |

### Account requests, user requests, and user journals

`AccountRequest` is an **account-level aggregate counter**. It groups matching
requests by tenant, date, controller, and action. It supports the Analytics
dashboard but cannot identify which user produced a request.

`UserRequest` is an **aggregate counter**. Repeated matching requests increase
`request_count`; the row is intended for totals and grouped reports. It does
not preserve the time of every individual request and must not be used to prove
that a business operation occurred.

`UserJournal` is an **individual request event**. Its tenant-scoped `event_uid`
identifies the captured event, `date` stores its reporting and retention day,
and `created_at` records the exact time it was stored. When `enable_journals`
is true, normalized request, user, and session dimensions are available for
operational history and working-hours reports.

In short:

- query `account_requests` to answer **how many matching requests reached an
  endpoint across the account**;
- query `user_requests` to answer **how many matching requests** a user made;
- query retained `user_journals` to answer **when individual requests** were
  captured;
- query `user_logs` to answer **which explicit auditable operations** the user
  performed.

Neither request table replaces `UserLog`. A controller request can finish
without representing a business change, while one business operation may also
emit multiple outcome events.

The `/audit/logs` report queries only `UserLog` or `AccountLog`. LesliShield
controls access to the controller through role permissions. Every role with
that permission may select either collection and see its account-wide history.
Both list and detail queries begin from the current Audit account, so granting
access to Logs never weakens tenant isolation.

The `/audit/requests` report always queries `UserRequest` through the current
Audit account. Owners and administrators can review all users in that account;
other roles granted access to the report remain limited to their own rows.
Authorization changes the scope within the tenant, never the tenant boundary.

The accounts table uses `create_table_lesli_shared_account_10(:lesli_audit)` and adds a unique index over `account_id`, so each core account has exactly one audit account. Request and device tables use a dedicated `date` column for their aggregation bucket and normal Rails timestamps for record lifecycle metadata.

The engine owns its foreign-key lifecycle rules. Core account soft deletion
keeps every physical row intact. Hard deletion cascades from the core account
to its Audit account and then to all tenant audit data. A hard-deleted user
cascades aggregate request rows and nullifies actor references on journals and
activity events, preserving their immutable identity snapshots.

LesliAudit installs the `lesliaudit` association on `Lesli::Account` through
`LesliAudit::AccountAssociations`. Every Audit-owned record then belongs to
`LesliAudit::Account`, while user-owned records also reference `Lesli::User`.
Destroying an Audit account is a deliberate hard purge and deletes its
dependent Audit records.

The initial schema enforces required tenant and dimension columns,
nonnegative 64-bit counters, and tenant-first unique indexes. Logger upserts
identify these constraints by index name so column order can continue to
support account-scoped access. Session identifiers remain nullable opaque
references and do not create a database dependency on LesliShield.

Journal rows use a tenant-scoped unique `event_uid`. Request counters and
journals are written synchronously by `LesliAudit::LoggerInterface`; no
background analytics job or processing lifecycle is required.

Device dimensions follow a separate path. `log_devices` parses and aggregates
the user agent only after a successful login; ordinary request logging never
increments `AccountDevice`.

Traffic follows another path. A `TrafficRollup` stores the provider, normalized
hostname and path, opaque host resource identity, daily totals, and provider
snapshot time in the same row. This keeps the feature to two tables while
preserving the URL that produced every day's data. `TrafficSnapshotImporter`
upserts one complete daily snapshot under an account lock. A retry or an older
snapshot cannot overwrite newer data. Omitted breakdown data is preserved;
an explicitly empty breakdown set removes existing values.

The standard Cloudflare flow is intentionally small: `GraphqlClient` requests
the aggregate data, `SnapshotConverter` converts it to LesliAudit snapshots,
and `TrafficSnapshotImporter` writes them. `CloudflareTrafficSync` records only
job state and the latest successful synchronization time.

See [Traffic](/engines/audit/traffic/overview#database-column-dictionary) for
the complete column-by-column contract of both traffic tables.

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

The retention operation is available to host schedulers through
`LesliAudit::RetentionCleanupJob`. Cleanup uses `analytics_retention_days` for
authenticated counters, journals, and login-device aggregates;
`traffic_retention_days` for imported rollups and Cloudflare synchronization
history; and `audit_retention_days` for account and user logs. Cleanup runs in
bounded batches. A `nil` setting skips that domain. Hard deletion of the Audit
account permanently removes every account-scoped collection through its
cascade rules.

Audit data can grow quickly. New queries should remain account-scoped and be supported by indexes matching their filters and grouping columns.

The retention and reliability rules differ between aggregated analytics,
short-lived journals, and durable activity events. See
[Architecture and Data Policy](/engines/audit/about/architecture) before
changing a table or adding a new event source.

See [Database Architecture](/engines/lesli/database/structure) and [Migration Versioning](/engines/lesli/database/versioning) for shared rules.
