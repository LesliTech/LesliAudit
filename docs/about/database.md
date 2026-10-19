# Database

LesliAudit uses collection code `05` and engine code `01`. Its migrations live under `db/migrate/v1.0` and are loaded into the host application's migration set.

| Migration code | Table | Responsibility |
| --- | --- | --- |
| `05.01.00.01.10` | `lesli_audit_accounts` | Engine state for a Lesli account |
| `05.01.11.01.10` | `lesli_audit_account_logs` | Account-level activity records |
| `05.01.11.02.10` | `lesli_audit_account_devices` | Aggregated browser, platform, and device observations |
| `05.01.11.03.10` | `lesli_audit_account_requests` | Account request counts by controller and action |
| `05.01.12.01.10` | `lesli_audit_user_logs` | User-specific activity records |
| `05.01.12.02.10` | `lesli_audit_user_journals` | User work-session journal data |
| `05.01.12.03.10` | `lesli_audit_user_requests` | User request analytics |

The accounts table uses `create_table_lesli_shared_account_10(:lesli_audit)` and adds a unique index over `account_id`, so each core account has exactly one audit account. Request and device tables use a dedicated `date` column for their aggregation bucket and normal Rails timestamps for record lifecycle metadata.

The initial schema enforces required tenant and dimension columns,
nonnegative 64-bit counters, and tenant-first unique indexes. Logger upserts
identify these constraints by index name so column order can continue to
support account-scoped access. Session identifiers remain nullable opaque
references and do not create a database dependency on LesliShield.

Run schema operations through the host application:

```shell
bin/rails lesli:db:prepare
bin/rails db:migrate:status
```

Audit data can grow quickly. New queries should remain account-scoped and be supported by indexes matching their filters and grouping columns.

The retention and reliability rules differ between aggregated analytics,
short-lived journals, and durable activity events. See
[Architecture and Data Policy](/engines/audit/about/architecture) before
changing a table or adding a new event source.

See [Database Architecture](/engines/lesli/database/structure) and [Migration Versioning](/engines/lesli/database/versioning) for shared rules.
