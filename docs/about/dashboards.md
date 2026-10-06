# Dashboards

LesliAudit registers a `calendar` component with LesliDashboard:

```ruby
module LesliAudit
  class Dashboard < Lesli::Shared::Dashboard
    COMPONENTS = %i[calendar]
  end
end
```

The component resolves to:

```text
app/views/lesli_audit/dashboards/_component-calendar.html.erb
```

The partial is currently an empty extension point. Applications should not treat it as a completed activity calendar until the engine supplies account-scoped audit data and presentation. A complete implementation should define the date range, account-scoped query, empty state, and authorization behavior in the same change.

## Register Existing Accounts

After installing LesliDashboard or adding a component, create missing dashboard records with:

```shell
bin/rails lesli_dashboard:register
```

Registration is idempotent for existing component names and does not overwrite persisted user settings.

See the [engine dashboard standard](/engines/lesli/contributing/engines#dashboard-page) before adding another component.
