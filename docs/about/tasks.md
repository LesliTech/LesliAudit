# Tasks

LesliAudit exposes two supported operational tasks. Run them through the host
application so they use its environment, database, queue adapter, and settings.

## Retry Pending Analytics

```shell
bin/rails lesli_audit:analytics:retry_pending
```

This task finds durable request inbox rows whose `processed_at` is null and
enqueues `LesliAudit::RequestAnalyticsJob` for each row in batches of 1,000.

| Property | Value |
| --- | --- |
| Environment | Any environment with the application, database, and Active Job loaded |
| Reads | Pending `lesli_audit_user_journals` rows |
| Writes | Jobs to the configured Active Job backend |
| External input | None |
| Repeatability | Safe to repeat; event UID and `processed_at` prevent duplicate counting |

Run it after a queue outage or enqueue failure. It does not process rows inline;
workers for the configured queue backend must be running.

## Apply Retention

Retention cleanup permanently deletes records older than the configured
periods. Confirm retention, export, and legal-hold requirements before running
this command in production.

```shell
bin/rails lesli_audit:retention:cleanup
```

| Property | Value |
| --- | --- |
| Environment | Any environment with the application and database loaded |
| Reads | `Lesli.config.audit` retention settings and Audit-owned tables |
| Writes | Permanently deletes expired Audit records in bounded batches |
| External input | None |
| Repeatability | Idempotent for the same cutoff and database state |

Cleanup never removes pending request inbox rows. Dates exactly on the cutoff
are retained. A retention value of `nil` skips its data class. The equivalent
job entry point for a host scheduler is `LesliAudit::RetentionCleanupJob`.

See [Configuration](/engines/audit/about/configuration) for defaults and
[Architecture and Data Policy](/engines/audit/about/architecture) for the
different retention guarantees of analytics, journals, and activity events.

