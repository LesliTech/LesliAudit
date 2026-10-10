# Installation

LesliAudit adds account and user activity history to a Lesli application. It requires Lesli `~> 5.1.0` and stores its records in the host database.

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

## Verify the Installation

```shell
bin/rails routes -g audit
bin/rails server
```

Visit `http://127.0.0.1:3000/audit`. Install LesliDashboard and run `bin/rails lesli_dashboard:register` when the Audit dashboard component should be available to existing accounts.

See [Dashboards](/engines/audit/about/dashboards), [Translations](/engines/audit/about/translations), [Database](/engines/audit/about/database), and [Frontend](/engines/audit/about/frontend) for the integration details.
