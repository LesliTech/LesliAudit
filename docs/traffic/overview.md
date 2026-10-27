# Traffic

Public pages may be served by a CDN without reaching the Rails application.
LesliAudit therefore does not count public views from a controller callback.
An external provider collects traffic, and the host imports daily aggregates.

## Data Model

`TrafficRollup` maps a provider-owned key directly to an opaque resource owned
by the host and stores one day of totals:

```ruby
rollup = LesliAudit::TrafficRollupImporter.call(
  account: audit_account,
  provider: "cloudflare",
  provider_key: "/ldonis",
  resource_type: "Profile",
  resource_id: 27,
  date: Date.new(2026, 10, 26),
  page_views: 184,
  visits: 126,
  breakdowns: [
    { dimension: "country", value: "GT", page_views: 112, visits: 79 },
    { dimension: "device", value: "mobile", page_views: 126, visits: 88 }
  ]
)
```

The engine does not define a polymorphic association to the resource. Keeping
the type and identifier opaque avoids a runtime dependency on the host model.
If a public path changes, later rows contain the new `provider_key`; both paths
remain queryable through the same `resource_type` and `resource_id`.

The Traffic report also groups this key across the selected period to show the
10 paths with the most visits. The provider remains part of the grouping, so
identical keys reported by different providers are never combined.

`TrafficBreakdown` stores optional `country`, `device`, `browser`,
`operating_system`, and `referrer` dimensions for the same day.

## Database Column Dictionary

### `lesli_audit_traffic_rollups`

| Column | Type | Meaning |
| --- | --- | --- |
| `id` | Primary key | Internal identifier of the daily snapshot. It has no meaning in the analytics provider. |
| `account_id` | Foreign key | Audit tenant that owns the traffic. Every query must remain scoped to this account. Hard deletion of the Audit account cascades to its traffic data. |
| `provider` | String | Normalized name of the collector or analytics provider, for example `cloudflare`. This is an identifier, not a credential. |
| `provider_key` | String | Provider-side key used to locate the public resource. For web analytics this can be a path such as `/ldonis`; another provider may use a hostname or opaque key. |
| `resource_type` | String | Opaque host-owned resource type, for example `Profile`, `Business`, or `Event`. LesliAudit does not constantize it or define a polymorphic association. |
| `resource_id` | Big integer | Positive identifier of the resource in the host application. It intentionally has no cross-engine foreign key. |
| `date` | Date | Calendar day represented by the provider snapshot. The provider adapter must normalize its timezone before importing. |
| `page_views` | Big integer | Nonnegative number of successful page views reported for the key and day. Its exact definition belongs to the provider contract. |
| `visits` | Big integer | Nonnegative number of visits or sessions reported for the key and day. It must not be described as unique people unless the provider explicitly guarantees that meaning. |
| `synced_at` | Date-time | Time at which the provider snapshot represented by this row was imported or refreshed. It is separate from Rails lifecycle timestamps. |
| `created_at` | Date-time | Time at which LesliAudit first created the row. |
| `updated_at` | Date-time | Time at which LesliAudit last replaced the row or its metadata. |

The unique index over `account_id`, `provider`, `provider_key`, and `date`
allows only one snapshot for a provider key per tenant and day. The resource
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
| `value` | String | Provider value within the dimension, such as `GT`, `mobile`, `Safari`, or `direct`. It is display and grouping data, not a person identifier. |
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

The importer replaces totals instead of incrementing them. Repeating a sync
for a day updates the existing rollup, updates returned breakdown values, and
deletes stale values that the provider omitted. The operation is transactional.
It refuses to attribute the same provider key and day to a different resource.

## Provider Boundary

LesliAudit does not make provider network requests in this proof of concept.
The host application owns the API adapter, schedule, retries, monitoring, and
credentials.

For Cloudflare, keep the API token server-side in encrypted Rails credentials
or the deployment secret manager. Do not expose it in the public beacon or
profile HTML. If encrypted Rails credentials are used, the deployment only
needs the corresponding Rails master key; do not duplicate the token in a
committed Kamal file.

## Privacy and Semantics

The tables contain aggregates only. They do not contain IP addresses, raw user
agents, cookies, fingerprints, or individual anonymous request records.

`page_views` and `visits` retain the provider's definitions. Do not relabel
`visits` as unique people unless a provider contract explicitly guarantees
that meaning.
