# Emitting Activity Events

Lesli Core exposes account and user logging methods when LesliAudit is
installed. Both methods return without writing when `enable_logs` is false.
When logging is enabled, persistence errors are intentionally raised.

## User Events

Use `Lesli::User#log` for an operation performed by or specifically associated
with a user:

```ruby
current_user.log(
  engine: MyEngine,
  source: self.class.name,
  action: action_name,
  operation: "ticket_closed",
  description: "Ticket closed successfully",
  session_id: session[:user_session_id],
  subject: ticket
)
```

The service stores only this allowlisted metadata:

| Field | Purpose |
| --- | --- |
| `engine` | Engine or subsystem that owns the operation |
| `source` | Controller, service, or job that emitted it |
| `action` | Source action or method |
| `operation` | Required stable event name |
| `description` | Human-readable explanation without secrets |
| `session_id` | Optional opaque session reference |
| `subject` | Optional record whose type and ID are snapshotted |

The user's `uid` is copied into `actor_uid`. This snapshot remains available if
the user is later hard-deleted and the nullable user reference is cleared.

Controllers inheriting from `Lesli::ApplicationLesliController` can use its
convenience method, which supplies engine, source, action, session, and user:

```ruby
log(
  operation: "ticket_closed",
  description: "Ticket closed successfully",
  subject: ticket
)
```

## Account Events

Use `Lesli::Account#log` for tenant-level lifecycle operations:

```ruby
account.log(
  "billing_policy_changed",
  "Billing policy updated",
  user: current_user
)
```

The optional `user:` argument records the actor and its immutable UID snapshot.

## Transaction Boundary

For an operation that requires audit evidence, write the business change and
the event in the same database transaction:

```ruby
Ticket.transaction do
  ticket.update!(status: "closed")

  current_user.log(
    engine: MyEngine,
    source: self.class.name,
    action: "close",
    operation: "ticket_closed",
    description: "Ticket closed successfully",
    subject: ticket
  )
end
```

Do not rescue and discard an audit persistence error inside this transaction.
If the event cannot be stored, the business change must roll back as well.

## Event Naming and Sensitive Data

Use stable, past-tense operation names such as `ticket_closed` and distinct
names for lifecycle outcomes such as `session_creation_attempted`,
`session_creation_failed`, and `session_creation_succeeded`.

Never place credentials, tokens, cookies, authorization headers, request
parameters, raw user-agent strings, or unrestricted serialized payloads in the
description. If richer structured event metadata becomes necessary, extend the
allowlist and schema explicitly instead of embedding JSON in a text field.

