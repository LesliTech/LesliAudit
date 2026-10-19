# Installation

LesliAudit adds account and user activity history to a Lesli application. It
requires Ruby 3.x, Rails `~> 8.1`, and Lesli `~> 5.1.0`, and stores its records
in the host database.

## Install the Engine

```shell
bundle add lesli_audit
```

The standard Lesli router mounts it at `/audit`:

```ruby
Rails.application.routes.draw do
  Lesli::Router.mount(self)
end
```

Mount it directly only when the host does not use the standard router:

```ruby
Rails.application.routes.draw do
  mount LesliAudit::Engine => "/audit"
end
```

Prepare migrations and initialize existing accounts:

```shell
bin/rails lesli:db:prepare
```

LesliAudit uses `device_detector` to classify request agents. No additional initializer is required for the default integration.
Request analytics is delivered through Active Job. Configure a persistent queue
adapter in production and schedule `LesliAudit::RetentionCleanupJob` once per
day. After a queue outage, pending request events can be recovered with:

```shell
bin/rails lesli_audit:analytics:retry_pending
```

Review the [configuration reference](/engines/audit/about/configuration) before
enabling production retention. LesliShield and LesliDashboard are optional;
Shield supplies an opaque session reference when available, while Dashboard
can render the registered Audit component.

## Upgrade

After updating the gem, run the standard preparation task. It loads new engine
migrations and initializes missing engine accounts without replacing existing
Audit data:

```shell
bundle update lesli_audit
bin/rails lesli:db:prepare
bin/rails db:migrate:status
```

## Verify the Installation

```shell
bin/rails routes -g audit
bin/rails server
```

Visit `http://127.0.0.1:3000/audit`. Install LesliDashboard and run `bin/rails lesli_dashboard:register` when the Audit dashboard component should be available to existing accounts.

See [Activity Events](/engines/audit/events/),
[Tasks](/engines/audit/about/tasks), [Dashboards](/engines/audit/about/dashboards),
[Translations](/engines/audit/about/translations),
[Database](/engines/audit/about/database), and
[Frontend](/engines/audit/about/frontend) for integration details.
