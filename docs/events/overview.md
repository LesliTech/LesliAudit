# Activity Events

Activity events describe explicit business or security operations. They are
different from request analytics: a request counter measures request volume, while an
activity event records an operation whose meaning is known by the calling code.

Typical events include:

- account initialization;
- successful or failed authentication operations;
- permission changes;
- creation, deletion, or state changes of important records.

Events are tenant-scoped and append-only. An attempted, failed, or succeeded
outcome is represented by a separate event, never by updating an older event.
The `/audit/logs` interface keeps the two event scopes explicit:

- **User events** (`UserLog`) describe operations performed by or specifically
  associated with a user.
- **Account events** (`AccountLog`) describe tenant-level lifecycle, policy, or
  security operations.

Both lists and their read-only detail pages always start from the current Audit
account. LesliShield decides which roles may access the Logs controller; once a
role has that permission, it can read both event collections for its account.
A record identifier can never be used to read an event from another account.

These events are stored in `lesli_audit_user_logs` or
`lesli_audit_account_logs`. They are not stored in `user_requests` or
`user_journals`: requests are usage data, journals are individual normalized
HTTP observations, and logs are explicit auditable operations.

Use activity events when the application must retain evidence of an operation.
Use request analytics for request-volume charts and operational timing. Browser,
platform, and device distribution comes from successful-login observations
recorded separately by the authentication flow. See [Emitting Events](/engines/audit/events/emitting) for the integration
API and [Architecture and Data Policy](/engines/audit/about/architecture) for
reliability and retention rules.

## Retention and Account Deletion

`audit_retention_days` applies equally to `UserLog` and `AccountLog`. Its
default value is `nil`, so retention cleanup preserves both event histories
until the host explicitly configures a positive number of days. Cleanup uses
`created_at`, deletes only rows older than the cutoff, and runs in bounded
batches.

A normal core-account soft deletion preserves the audit history. A deliberate
hard deletion cascades through the Audit account and permanently removes both
event collections with the rest of that tenant's Audit data. Confirm legal
hold and export requirements before enabling retention or hard deletion.

