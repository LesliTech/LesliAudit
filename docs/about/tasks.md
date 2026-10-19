# Tasks

LesliAudit exposes one supported operational task. Run it through the host
application so it uses the host environment, database, and settings.

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

Cleanup removes only processed journals; rows without `processed_at` are
preserved. Dates exactly on the cutoff are retained. A retention value of `nil`
skips its data class. The equivalent job entry point for a host scheduler is
`LesliAudit::RetentionCleanupJob`.

See [Configuration](/engines/audit/about/configuration) for defaults and
[Architecture and Data Policy](/engines/audit/about/architecture) for the
different retention guarantees of analytics, journals, and activity events.

