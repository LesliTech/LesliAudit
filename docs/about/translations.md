# Translations

LesliAudit reserves the `lesli_audit` namespace for all user-facing labels. Locale files live in `config/locales/translations.<locale>.yml`; the engine currently provides files for English, Spanish, French, Italian, and Portuguese.

New labels should follow the standard engine, bucket, and label structure:

```yaml
en:
  lesli_audit:
    users:
      title: "User activity"
      empty: "No activity has been recorded"
    shared:
      requests: "Requests"
```

Use the complete key from Ruby or ERB:

```erb
<%= I18n.t("lesli_audit.users.title") %>
```

The shipped locale files are currently empty, so adding a key also requires replacing the corresponding hard-coded interface text. Add the same key to every supported locale and preserve interpolation variables between languages.

When LesliBabel is installed, synchronize the local files with:

```shell
bin/rails lesli_babel:scan
bin/rails lesli_babel:import
```

The files in LesliAudit remain the version-controlled source shipped with the gem. Review any Babel-generated changes before committing them.

See the [engine documentation standard](/engines/lesli/contributing/engines) for namespace and bucket conventions.
