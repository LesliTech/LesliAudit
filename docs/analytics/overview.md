# Request Analytics

LesliAudit captures traffic from authenticated controllers inheriting from
`Lesli::ApplicationLesliController`. Its `after_action` callback sends the
current user, controller, action, optional session, request ID, and user agent
to the analytics pipeline. Capture is account-scoped and fail-open: analytics
failure does not change an otherwise successful HTTP response.

## Processing Pipeline

1. The request ID becomes a tenant-scoped idempotency key.
2. The raw user agent is parsed and discarded.
3. One `UserJournal` inbox row is inserted for the individual request.
4. `LesliAudit::RequestAnalyticsJob` processes that row under a lock.
5. The job updates enabled aggregate counters and sets `processed_at` in one
   transaction.
6. If journal retention is disabled, the successfully processed inbox payload
   is scrubbed, while its event identity remains temporarily for deduplication.

Job retries cannot count the same inbox event twice. If enqueueing fails, the
pending row remains recoverable with the
[`lesli_audit:analytics:retry_pending`](/engines/audit/about/tasks#retry-pending-analytics)
task.

## UserRequest and UserJournal Are Different

| Record | Meaning | Typical question |
| --- | --- | --- |
| `UserRequest` | Grouped counter by user, optional session, date, controller, and action | How many matching requests did this user make? |
| `UserJournal` | One normalized record for an individual captured request | When did this user's individual requests occur? |
| `UserLog` | Explicit append-only business or security event | Which auditable operation did this user perform? |

`UserRequest#request_count` increases as matching journal events are processed.
It is compact reporting data and does not retain every request timestamp.

`UserJournal` is both the durable delivery inbox and, when `enable_journals` is
true, detailed operational history. Its `created_at` supports first/last
activity calculations. A journal is not audit evidence: it proves that an HTTP
request was observed, not that a business change succeeded.

`UserLog` is written separately by application code that knows the business
meaning and outcome. Do not infer a `UserLog` from the presence of either
request record.

## Reports

With the engine mounted at `/audit`, the current interface exposes:

| Route | Data source | Scope |
| --- | --- | --- |
| `/audit/analytics` | `AccountRequest` and `AccountDevice` aggregates | Current tenant |
| `/audit/users` | Core users and retained, processed `UserJournal` rows | Current tenant |
| `/audit/requests` | `UserRequest` aggregates | Current user |
| `/audit/visitors` | Compatibility alias for `/audit/analytics` | Current tenant |

Device and browser figures are request counts, not unique people or physical
devices. The interface therefore uses “traffic” and “requests” rather than
“visitors.”

See [Configuration](/engines/audit/about/configuration) for capture modes,
[Database](/engines/audit/about/database#choosing-the-correct-record) for table
semantics, and [Architecture and Data Policy](/engines/audit/about/architecture)
for privacy and retention guarantees.

