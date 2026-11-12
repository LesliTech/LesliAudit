# Cloudflare Traffic

Cloudflare Traffic is LesliAudit's standard Traffic integration. It is useful
when Cloudflare serves a cached public resource without a request reaching
Rails. LesliAudit downloads aggregate analytics and imports complete daily
snapshots; it never installs a tracking beacon or logs one row per anonymous
request.

## Responsibility Boundary

The integration intentionally follows three steps:

```text
Cloudflare GraphQL POST request
  -> SnapshotConverter
  -> TrafficSnapshotImporter
```

LesliAudit owns the API client, converter, importer, synchronization job,
status table, rake tasks, retention, and Traffic report. The host supplies only
deployment-specific values: credentials, zone, hostnames, account IDs, the
path-to-resource resolver, and the recurring schedule. This keeps host models
out of the engine without moving the standard integration out of LesliAudit.

## Exact Metric Contract

The reference integration queries Cloudflare's
`httpRequestsAdaptiveGroups` dataset with `requestSource: "eyeball"`, a UTC
day, a hostname, and `clientRequestPath` groups.

| LesliAudit field | Cloudflare field | Exact meaning in this integration |
| --- | --- | --- |
| `page_views` | `count` | Number of end-user HTTP requests Cloudflare reports for the mapped hostname and path during the UTC day. It is not a browser DOM/page-load event and is not unique. Reloads and repeated requests can increase it. |
| `visits` | `sum.visits` | Number of Cloudflare visits for the mapped hostname and path. Cloudflare defines a visit as a page view reached from a direct link or a referrer whose hostname differs from the requested hostname. One visit can include multiple page views. |

The name `page_views` is LesliAudit's presentation contract for mapped resource
requests; the unmodified source is Cloudflare `count`. Neither field means
unique people, authenticated users, successful business operations, or
billable Cloudflare traffic. Adaptive datasets can be sampled and a repeated
query can produce adjusted totals, which is why recent days are reimported.

See Cloudflare's documentation for
[`httpRequestsAdaptiveGroups`](https://developers.cloudflare.com/analytics/graphql-api/migration-guides/graphql-api-analytics/),
[`requestSource` filtering](https://developers.cloudflare.com/analytics/graphql-api/features/filtering/),
and [adaptive sampling](https://developers.cloudflare.com/analytics/faq/graphql-api-inconsistent-results/).

## Installation Checklist

1. Install LesliAudit and run `bin/rails lesli:db:prepare`.
2. Create a custom Cloudflare token with **Account · Account Analytics · Read**
   and restrict its Zone Resources to the required zone.
3. Store the token in Rails encrypted credentials or the deployment secret
   manager. Never store it in LesliAudit tables or client-side code.
4. Configure `Lesli.config.audit[:cloudflare]` with the zone ID, allowed
   hostnames, target Lesli account IDs, and query limits.
5. Implement a callable path resolver that returns `resource_type` and
   `resource_id`, or `nil` for paths that should be ignored.
6. Schedule `LesliAudit::CloudflareTrafficSyncJob.enqueue_recent` in the host.
7. Run an initial backfill, then reimport recent days on every scheduled run.

The token can be stored at `cloudflare.analytics.token` in encrypted Rails
credentials or provided through `CLOUDFLARE_ANALYTICS_TOKEN`.

## Jobs and Backfill

LesliAudit exposes:

```shell
# Reimport the configured recent period for every configured account.
bin/rails cloudflare_traffic:sync

# Import 30 complete days for Lesli::Account ID 1.
bin/rails "cloudflare_traffic:backfill[1,30]"
```

The default production schedule runs once daily and refreshes the last three
complete UTC days. The initial backfill defaults to 30 days. Provider retention
and query limits depend on the Cloudflare plan, so a longer backfill must be
validated against the dataset settings returned for the zone.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Traffic remains empty | Confirm the integration is enabled, the account ID is configured, the Audit account exists, and the path resolver returns a resource. |
| Authentication or authorization error | Verify the token value, **Account Analytics: Read** permission, and Zone Resources restriction. These errors are intentionally not retried. |
| Dataset disabled or missing fields | Inspect the zone's `httpRequestsAdaptiveGroups` settings. Country, device, or referrer breakdowns are imported only when their fields are available. |
| Results differ between runs | Cloudflare adaptive data may be sampled or adjusted. Query short daily ranges and allow recent-day reimports. |
| Import exceeds its page limit | Raise the configured safety limit only after checking the zone `maxPageSize`, dataset duration, and expected path cardinality. A partial result is never silently stored. |
| Last synchronization is stale | Inspect `lesli_audit_cloudflare_traffic_syncs`, the queue worker, schedule, and most recent error. The report warns after 36 hours without a successful synchronization. |
| A path is missing | Confirm the configured hostname and inspect the resolver. Query strings and fragments are removed before resource matching. |

## Evidence and Privacy

Traffic is external, eventually consistent analytics. It can be sampled,
delayed, reclassified, or replaced by a newer provider snapshot. It is **not
audit evidence** and must not be used to prove that a user performed an action
or that a business transaction succeeded. Use `UserLog` or `AccountLog` for
explicit auditable operations.

The integration persists aggregates only. It does not store Cloudflare tokens,
IP addresses, cookies, fingerprints, raw user agents, referrer paths, query
strings, URL fragments, or individual anonymous requests.
