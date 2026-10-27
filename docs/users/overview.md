# Users

The Users report describes the people registered in the current account. It
combines core user status with a small amount of retained journal data so an
authorized operator can understand account health and observed working hours.

The report intentionally contains only person-centered information:

- current totals for registered, enabled, deactivated, and deleted users;
- users who signed in during the last 30 days;
- attention counts for unconfirmed, never-signed-in, failed-sign-in, and
  locked users;
- registration totals for each of the last 12 calendar months;
- the 20 most recent first/last activity records per user and day from the
  last 30 days.

## Boundaries with Other Reports

Users does not show request totals, controllers, browsers, devices, or
operating systems. Account-wide traffic belongs to **Analytics**, and the
filterable per-user endpoint report belongs to **Requests**.

The working-hours table does not list journals or count requests. It reduces
retained `UserJournal` rows to the earliest and latest observed timestamp for
each user and day. Transient journals and journals older than 30 days are not
used. These timestamps show observed application activity; they are not an
employment time clock and are not audit evidence.

`UserLog` and `AccountLog` are also excluded. Explicit business and security
events belong to **Logs**.

## Access and Tenant Isolation

LesliShield role privileges determine whether a user may open `/audit/users`.
The report does not add owner, administrator, or current-user restrictions of
its own. Once a role has access, it can read the Users dashboard for its
account.

Every core-user query begins with `current_user.account.users`. Working-hours
queries additionally require journals from `current_user.account.audit`.
Users, registrations, and journals from another account can never enter the
report.

## Demo Data

In development or demo mode, `db/seed/users.rb` creates 100 users with a
complete distribution of states and registrations across the last 12 months.
It also creates retained first/last activity observations for 20 demo users
over 14 days. The seed owns records with the `DEV-USR-` prefix, is safe to run
repeatedly, and does not create request aggregates or audit events.

See [Analytics](/engines/audit/analytics/overview),
[Activity Events](/engines/audit/events/overview), and
[Database](/engines/audit/about/database) for the neighboring data contracts.

