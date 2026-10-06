# Database

LesliAudit uses collection code `05` and engine code `01`. Its migrations live under `db/migrate/v1.0` and are loaded into the host application's migration set.

| Migration code | Table | Responsibility | Important relationships |
| --- | --- | --- | --- |
| `05.01.00.01.10` | `lesli_audit_accounts` | Engine state for a Lesli account | Required core account reference |
| `05.01.11.01.10` | `lesli_audit_account_logs` | Account-level activity records | Audit account and optional user |
| `05.01.11.02.10` | `lesli_audit_account_devices` | Aggregated browser, platform, and device observations | Audit account |
| `05.01.11.03.10` | `lesli_audit_account_requests` | Account request counts by controller and action | Audit account |
| `05.01.12.01.10` | `lesli_audit_user_logs` | User-specific activity records | Audit account and core user |
| `05.01.12.02.10` | `lesli_audit_user_journals` | User work-session journal data | Audit account and core user |
| `05.01.12.03.10` | `lesli_audit_user_requests` | User request analytics | Audit account and core user |

The accounts table uses `create_table_lesli_shared_account_10(:lesli_audit)`. Request and device tables enforce composite uniqueness for their aggregation dimensions; preserve those indexes when changing how events are grouped.

Run schema operations through the host application:

```shell
bin/rails lesli:db:prepare
bin/rails db:migrate:status
```

Audit data can grow quickly. New queries should remain account-scoped and be supported by indexes matching their filters and grouping columns.

See [Database Architecture](/engines/lesli/database/structure) and [Migration Versioning](/engines/lesli/database/versioning) for shared rules.
