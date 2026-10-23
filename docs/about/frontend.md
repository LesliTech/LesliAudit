# Frontend

LesliAudit renders inside Lesli's authenticated application shell. Views use
LesliView for shared layouts, headers, tables, toolbars, and charts, while
Tailwind CSS handles engine-specific presentation.

## Tailwind Stylesheet

The editable entrypoint and its generated Rails asset are separate:

```text
source/tailwind/application.css
        ↓ build
app/assets/stylesheets/lesli_audit/application.css
```

Edit the file under `source/tailwind`; do not edit the compiled stylesheet by
hand. Commit the generated asset whenever the source or a scanned view changes.

The entrypoint uses `source(none)`, so Tailwind does not discover templates
automatically. Every view or helper containing Tailwind utilities must be
covered by an `@source` rule. The current page-specific sources are:

```css
@source "../../app/views/lesli_audit/users/index.html.erb";
@source "../../app/views/lesli_audit/visitors/index.html.erb";
@source "../../app/views/lesli_audit/logs/show.html.erb";
```

Add another source when migrating or creating a view that contains utilities.
Tailwind cannot detect interpolated fragments such as
`"text-#{status}-600"`; map each state to a complete class string instead.

## Build the Asset

From a standard Lesli workspace, use the shared LesliAssets builder:

```shell
cd gems/LesliAssets
make build.tailwind
```

During frontend development, use the watcher:

```shell
make watch.tailwind
```

The builder discovers LesliAudit's entrypoint and writes the compiled output to
`app/assets/stylesheets/lesli_audit/application.css`.

## View Conventions

- Wrap authenticated pages with `LesliView::Layout::Container` and use the
  shared header component.
- Prefer LesliView tables and charts instead of duplicating their structure.
- Give data tables a caption when surrounding content does not name them.
- Build responsive layouts mobile-first and preserve `min-w-0` where a table or
  chart lives inside a grid column.
- Keep data shaping in services. Inline styles are reserved for genuinely
  data-driven values, such as a clamped percentage width.
- Mark decorative icons with `aria-hidden="true"` and do not communicate state
  through color alone.

See [Views and Layouts](/engines/lesli/frontend/views),
[Styles with Tailwind CSS](/engines/lesli/frontend/styles), and the
[LesliView documentation](/gems/view/) for the shared conventions and component
APIs.
