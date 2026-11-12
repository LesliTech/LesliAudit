# Changelog

## 1.1.2 (unreleased)

- Update compatibility for Lesli 5.1, Ruby 3.3.5, and Rails 8.1.
- Restore and test the audit interface and service-based log creation.
- Move shared user associations to Lesli Core and align local engine accounts.
- Complete the Tailwind migration and address static-analysis findings.
- Adopt the shared LesliActions engine workflow and Linux CI platform.
- Establish the five report domains: Users, Analytics, Traffic, Requests, and
  Logs, with account isolation and LesliShield role authorization.
- Add provider-independent Traffic snapshots, Cloudflare normalization,
  idempotent concurrent imports, retention, demo data, and the Traffic report.
- Move the standard Cloudflare client, converter, job, status model, migration,
  and tasks into LesliAudit; hosts now provide only deployment configuration,
  resource mapping, and scheduling.
- Document the complete schema, request and audit boundaries, Cloudflare metric
  definitions, installation, synchronization, backfill, and troubleshooting.
