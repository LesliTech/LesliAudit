# Activity Events

Activity events describe explicit business or security operations. They are
different from request analytics: a request counter measures traffic, while an
activity event records an operation whose meaning is known by the calling code.

Typical events include:

- account initialization;
- successful or failed authentication operations;
- permission changes;
- creation, deletion, or state changes of important records.

Events are tenant-scoped and append-only. An attempted, failed, or succeeded
outcome is represented by a separate event, never by updating an older event.
The current `/audit/logs` interface shows the authenticated user's event
history and exposes each event as a read-only detail page.

These events are stored in `lesli_audit_user_logs` or
`lesli_audit_account_logs`. They are not stored in `user_requests` or
`user_journals`: requests are traffic data, journals are individual normalized
HTTP observations, and logs are explicit auditable operations.

Use activity events when the application must retain evidence of an operation.
Use request analytics for traffic charts, browser distribution, and operational
timing. See [Emitting Events](/engines/audit/events/emitting) for the integration
API and [Architecture and Data Policy](/engines/audit/about/architecture) for
reliability and retention rules.

