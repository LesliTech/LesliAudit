# Traffic

Public pages may be served by a CDN without reaching the Rails application.
LesliAudit therefore does not count public views from a controller callback.
An external provider collects traffic, and the host imports daily aggregates.

## Data Model

`TrafficRollup` maps a normalized hostname and path directly to an opaque
resource owned by the host and stores one day of totals. Cloudflare input must
first pass through its DTO and is then imported as one complete snapshot:

```ruby
snapshot = LesliAudit::CloudflareTrafficSnapshot.new(
  hostname: "www.example.com",
  path: "/ldonis?utm_source=newsletter",
  resource_type: "Profile",
  resource_id: 27,
  date: Date.new(2026, 10, 26),
  page_views: 184,
  visits: 126,
  snapshot_at: Time.zone.local(2026, 10, 26, 22),
  breakdowns: [
    { dimension: "country", value: "GT", page_views: 112, visits: 79 },
    { dimension: "device", value: "mobile", page_views: 126, visits: 88 }
  ]
)

rollup = LesliAudit::TrafficSnapshotImporter.call(
  account: audit_account,
  snapshot: snapshot
)
```

The engine does not define a polymorphic association to the resource. Keeping
the type and identifier opaque avoids a runtime dependency on the host model.
If a public path changes, both paths remain queryable through the same
`resource_type` and `resource_id`.

The Traffic report groups this identity across the selected period to show the
10 paths with the most visits. Provider and hostname remain part of the group,
so identical paths from different sites or providers are never combined.

## Traffic Report

The report is available at `/audit/traffic` through the engine's `traffic`
resource. Access is authenticated and authorized by LesliShield in the same
way as the other LesliAudit reports. Every query starts from the current
user's Audit account; selecting a period or resource never removes that tenant
scope.

The summary shows page views, visits, resources, and tracked paths. The trend
compares page views and visits by date. The rankings show the 10 most visited
paths and resources, while the breakdown cards show countries, devices, and
referrers. Breakdown percentages always use the complete filtered total as
their denominator. When values outside the first 10 exist, the report groups
their counts into `Other` instead of making the visible percentages appear to
represent the entire dataset.

Users can filter the report by period or by the opaque resource type and ID.
The synchronization panel reads the latest successful
`CloudflareTrafficSync`. Standalone demo data falls back to the most recent
`snapshot_at` for the account. Data older than 36 hours is marked as
potentially outdated. Synchronization freshness intentionally ignores report
filters, because filtering historical data must not make a current account
synchronization look stale.

`TrafficBreakdown` stores optional `country`, `device`, `browser`,
`operating_system`, and `referrer` dimensions for the same day.

## Database Column Dictionary

### `lesli_audit_traffic_rollups`

| Column | Type | Meaning |
| --- | --- | --- |
| `id` | Primary key | Internal identifier of the daily snapshot. It has no meaning in the analytics provider. |
| `account_id` | Foreign key | Audit tenant that owns the traffic. Every query must remain scoped to this account. Hard deletion of the Audit account cascades to its traffic data. |
| `provider` | String | Normalized name of the collector or analytics provider, for example `cloudflare`. This is an identifier, not a credential. |
| `hostname` | String | Lowercase hostname without scheme, credentials, port, path, query string, fragment, or trailing dot. |
| `path` | String | Normalized URL path beginning with `/`. Query strings and fragments are removed before persistence. |
| `resource_type` | String | Opaque host-owned resource type, for example `Profile`, `Business`, or `Event`. LesliAudit does not constantize it or define a polymorphic association. |
| `resource_id` | Big integer | Positive identifier of the resource in the host application. It intentionally has no cross-engine foreign key. |
| `date` | Date | Calendar day represented by the provider snapshot. The provider adapter must normalize its timezone before importing. |
| `page_views` | Big integer | Nonnegative provider metric presented as resource page views. For the Cloudflare adapter this is `httpRequestsAdaptiveGroups.count`: end-user HTTP requests for the mapped hostname and path, not browser DOM events or unique views. |
| `visits` | Big integer | Nonnegative number of visits or sessions reported for the key and day. It must not be described as unique people unless the provider explicitly guarantees that meaning. |
| `snapshot_at` | Date-time | Provider snapshot version used to reject retries and out-of-order imports. A replacement must be newer than the stored value. |
| `created_at` | Date-time | Time at which LesliAudit first created the row. |
| `updated_at` | Date-time | Time at which LesliAudit last replaced the row or its metadata. |

The unique index over `account_id`, `provider`, `hostname`, `path`, and `date`
allows only one snapshot for a provider path per tenant and day. The resource
index over `account_id`, `resource_type`, `resource_id`, and `date` supports
history queries even when the public path changes. The standalone date index
supports retention cleanup.

### `lesli_audit_traffic_breakdowns`

| Column | Type | Meaning |
| --- | --- | --- |
| `id` | Primary key | Internal identifier of the dimension value. |
| `account_id` | Foreign key | Audit tenant that owns the row. It is repeated intentionally for direct tenant-scoped queries; model validation requires it to match the rollup account. |
| `traffic_rollup_id` | Foreign key | Daily rollup to which this dimension value belongs. Deleting the rollup cascades to its breakdowns. |
| `dimension` | String | Normalized classification name. Supported values are `country`, `device`, `browser`, `operating_system`, and `referrer`. |
| `value` | String | Provider value within the dimension, such as `GT`, `mobile`, `safari`, or `direct`. It is display and grouping data, not a person identifier. |
| `page_views` | Big integer | Nonnegative page-view count attributed to this dimension value. |
| `visits` | Big integer | Nonnegative visit count attributed to this dimension value. |
| `created_at` | Date-time | Time at which LesliAudit first created the dimension row. |
| `updated_at` | Date-time | Time at which the latest import refreshed the dimension row. |

The unique index over `account_id`, `traffic_rollup_id`, `dimension`, and
`value` prevents duplicate values within the same breakdown. Counts for one
dimension commonly add up to the parent rollup, but the database does not
enforce that equality because providers may sample data, suppress small
segments, or report an unknown remainder.

Neither table stores API tokens, IP addresses, raw user agents, cookies,
fingerprints, or one row per anonymous request.

## Import Semantics

`CloudflareTrafficSnapshot` is the provider boundary. It normalizes hostname,
path, country, device, browser, operating system, and referrer before the
database is touched. Referrers retain only a hostname; URL credentials, paths,
query strings, and fragments are discarded. The DTO requires complete totals,
a provider snapshot timestamp, and the opaque host resource identity.

`TrafficSnapshotImporter` replaces totals instead of incrementing them. It
locks the Audit account and executes the rollup and breakdown upserts in one
transaction. The unique database index protects the same identity if another
writer bypasses the application lock. A retry with the same `snapshot_at` and
an older out-of-order snapshot are no-ops; only a strictly newer snapshot can
replace stored data.

Breakdown presence is intentional:

- Omitting `breakdowns` means Cloudflare did not provide that dataset, so
  existing breakdown rows remain unchanged.
- Passing `breakdowns: []` means the complete dataset is empty, so existing
  breakdown rows are removed.
- Passing breakdown rows upserts those values and removes stale values not
  present in the complete replacement.

The importer refuses to attribute the same provider hostname, path, and day to
a different resource. Any failure rolls back both totals and breakdowns.

## Provider Boundary

LesliAudit owns the standard Cloudflare adapter. `Cloudflare::GraphqlClient`
queries `httpRequestsAdaptiveGroups` one UTC day at a time,
`Cloudflare::SnapshotConverter` converts supported paths to
`CloudflareTrafficSnapshot` objects, and `TrafficSnapshotImporter` persists
them. The host supplies the token, zone, hostnames, account IDs, resource
resolver, and schedule.

The Cloudflare adapter stores `httpRequestsAdaptiveGroups.count` as
`page_views`: the number of end-user HTTP requests reported for a mapped
hostname and path in one UTC day. It stores `sum.visits` as `visits`;
Cloudflare defines a visit as a page view reached directly or from a different
referrer hostname, and one visit can contain multiple page views. Neither
metric is unique people or a browser-side DOM event. See the complete
[Cloudflare Traffic contract](/engines/audit/traffic/cloudflare).

The adapter imports country, device, and referrer hostname only when those
fields are available for the zone. It does not infer browser or operating
system from a raw user agent. Referrer paths and query strings never cross the
DTO boundary.

For Cloudflare, keep the API token server-side in encrypted Rails credentials
or the deployment secret manager. Do not expose it in the public beacon or
profile HTML. If encrypted Rails credentials are used, the deployment only
needs the corresponding Rails master key; do not duplicate the token in a
committed Kamal file.

## Privacy and Semantics

The tables contain aggregates only. They do not contain IP addresses, raw user
agents, cookies, fingerprints, or individual anonymous request records.

Traffic is external, eventually consistent reporting data. It can be sampled,
delayed, adjusted, or replaced by a newer snapshot. It is not audit evidence
and must never be used to prove that a user completed an operation. Explicit
business and security evidence belongs in `UserLog` or `AccountLog`.
