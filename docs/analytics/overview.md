# Request Analytics

LesliAudit captures traffic from authenticated controllers inheriting from
`Lesli::ApplicationLesliController`. Its `after_action` callback sends the
current user, controller, action, and optional session to
`LesliAudit::LoggerInterface#log_requests`. Request data is written
synchronously and remains scoped to the current account.

## Request Capture

1. When analytics is enabled, `AccountRequest` increments the counter matching
   the current date, controller, and action.
2. When a session is available, `UserRequest` increments the corresponding
   per-user counter.
3. When journals are enabled, `UserJournal` records the individual request.

Device capture is intentionally separate. The authentication flow calls
`log_devices` only after a successful login.

## UserRequest and UserJournal Are Different

| Record | Meaning | Typical question |
| --- | --- | --- |
| `UserRequest` | Grouped counter by user, optional session, date, controller, and action | How many matching requests did this user make? |
| `UserJournal` | One normalized record for an individual captured request | When did this user's individual requests occur? |
| `UserLog` | Explicit append-only business or security event | Which auditable operation did this user perform? |

`UserRequest#request_count` increases when matching requests are captured.
It is compact reporting data and does not retain every request timestamp.

`UserJournal` is detailed operational history. Its `created_at` supports
first/last activity calculations. A journal is not audit evidence: it proves
that an HTTP request was observed, not that a business change succeeded.

`UserLog` is written separately by application code that knows the business
meaning and outcome. Do not infer a `UserLog` from the presence of either
request record.

## Reports

With the engine mounted at `/audit`, the current interface exposes:

| Route | Data source | Scope |
| --- | --- | --- |
| `/audit/analytics` | `AccountRequest` and `AccountDevice` aggregates | Current tenant |
| `/audit/users` | Core users and retained `UserJournal` rows | Current tenant |
| `/audit/requests` | `UserRequest` aggregates | Current user |
| `/audit/visitors` | Compatibility alias for `/audit/analytics` | Current tenant |

Device and browser figures count successful logins by normalized agent
category. They are not unique people or physical devices. Device capture is
invoked explicitly by the authentication flow and never by `log_requests`.

See [Configuration](/engines/audit/about/configuration) for capture modes,
[Database](/engines/audit/about/database#choosing-the-correct-record) for table
semantics, and [Architecture and Data Policy](/engines/audit/about/architecture)
for privacy and retention guarantees.

