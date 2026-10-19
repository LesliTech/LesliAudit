# Configuration

LesliAudit reads its settings from `Lesli.config.audit`. Override only the
values that differ from the defaults and merge them with the existing hash so
future engine defaults are preserved:

```ruby
# config/initializers/lesli.rb
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

## Settings

| Setting | Type | Default | Behavior |
| --- | --- | --- | --- |
| `enable_logs` | Boolean | `true` | Enables explicit account and user activity events |
| `enable_journals` | Boolean | `true` | Retains processed request events as user journal history |
| `enable_analytics` | Boolean | `true` | Builds account, user, browser, platform, and device aggregates |
| `journal_retention_days` | Positive integer or `nil` | `90` | Retention period for processed, retained journals |
| `analytics_retention_days` | Positive integer or `nil` | `400` | Retention period for aggregate analytics and scrubbed deduplication rows |
| `audit_retention_days` | Positive integer or `nil` | `nil` | Retention period for append-only activity events |

`nil` disables automatic cleanup for that data class. Invalid retention values
raise `ArgumentError` when cleanup runs. Keep `audit_retention_days` unset until
the host application has defined its legal-hold, export, and deletion policy.

## Analytics and Journal Modes

The analytics and journal switches are independent:

| Analytics | Journals | Result |
| --- | --- | --- |
| Enabled | Enabled | Build aggregates and retain the normalized request journal |
| Enabled | Disabled | Build aggregates, then scrub the inbox row down to its deduplication identity |
| Disabled | Enabled | Retain the request journal without updating aggregate counters |
| Disabled | Disabled | Do not capture a request event |

Explicit activity events are controlled only by `enable_logs`; the analytics
switches do not affect them.

## Active Job

Request analytics is processed by `LesliAudit::RequestAnalyticsJob`. Development
may use the host application's synchronous adapter, but production must use a
persistent Active Job backend so accepted inbox rows are processed after web
process restarts. The job retries processing failures ten times with increasing
delays.

Schedule `LesliAudit::RetentionCleanupJob` once per day after choosing retention
periods. LesliAudit intentionally does not select a scheduler or queue because
those are host-application concerns. See [Tasks](/engines/audit/about/tasks) for
manual cleanup and queue-recovery commands.

## Optional Engines

LesliShield is optional. When installed, its session identifier is recorded as
opaque metadata; LesliAudit does not create a foreign key to Shield tables.

LesliDashboard is also optional. Its installation does not change audit capture
or retention. See [Dashboards](/engines/audit/about/dashboards) when enabling
the Audit dashboard component.

