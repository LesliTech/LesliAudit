# frozen_string_literal: true

core_account = Lesli::Account.first
return unless core_account

audit_account = core_account.audit || LesliAudit::Account.create!(
    account: core_account,
    name: core_account.name
)

resources = [ {
    resource_type: "Profile",
    resource_id: 1_001,
    path: "/demo/sofia",
    baseline: 92
}, {
    resource_type: "Profile",
    resource_id: 1_002,
    path: "/demo/mateo",
    baseline: 78
}, {
    resource_type: "Profile",
    resource_id: 1_003,
    path: "/demo/valentina",
    baseline: 72
}, {
    resource_type: "Profile",
    resource_id: 1_004,
    path: "/demo/santiago",
    baseline: 68
}, {
    resource_type: "Business",
    resource_id: 2_001,
    path: "/demo/cafe",
    baseline: 64
}, {
    resource_type: "Business",
    resource_id: 2_002,
    path: "/demo/studio",
    baseline: 56
}, {
    resource_type: "Business",
    resource_id: 2_003,
    path: "/demo/bakery",
    baseline: 52
}, {
    resource_type: "Event",
    resource_id: 3_001,
    path: "/demo/festival",
    baseline: 38
}, {
    resource_type: "Event",
    resource_id: 3_002,
    path: "/demo/conference",
    baseline: 44
}, {
    resource_type: "Event",
    resource_id: 3_003,
    path: "/demo/workshop",
    baseline: 34
} ].freeze

split = lambda do |total, weights|
    remaining = total
    weights.each_with_index.map do |weight, index|
        value = index == weights.length - 1 ? remaining : (total * weight).round
        remaining -= value
        value
    end
end

resources.each_with_index do |resource, resource_index|
    (29.days.ago.to_date..Date.current).each_with_index do |date, day_index|
        weekday_lift = date.on_weekend? ? 8 : 18
        trend = day_index * (resource_index + 1)
        page_views = resource[:baseline] + weekday_lift + trend
        visits = (page_views * 0.72).round

        country_views = split.call(page_views, [ 0.72, 0.18, 0.10 ])
        country_visits = split.call(visits, [ 0.72, 0.18, 0.10 ])
        device_views = split.call(page_views, [ 0.68, 0.27, 0.05 ])
        device_visits = split.call(visits, [ 0.68, 0.27, 0.05 ])
        referrer_views = split.call(page_views, [ 0.42, 0.31, 0.17, 0.10 ])
        referrer_visits = split.call(visits, [ 0.42, 0.31, 0.17, 0.10 ])

        breakdowns = []
        %w[GT US MX].each_with_index do |value, index|
            breakdowns << {
                dimension: "country",
                value:,
                page_views: country_views[index],
                visits: country_visits[index]
            }
        end
        %w[mobile desktop tablet].each_with_index do |value, index|
            breakdowns << {
                dimension: "device",
                value:,
                page_views: device_views[index],
                visits: device_visits[index]
            }
        end
        %w[direct instagram google facebook].each_with_index do |value, index|
            breakdowns << {
                dimension: "referrer",
                value:,
                page_views: referrer_views[index],
                visits: referrer_visits[index]
            }
        end

        snapshot = LesliAudit::CloudflareTrafficSnapshot.new(
            hostname: "demo.lesli.dev",
            path: resource[:path],
            resource_type: resource[:resource_type],
            resource_id: resource[:resource_id],
            date:,
            page_views:,
            visits:,
            snapshot_at: date.in_time_zone.end_of_day,
            breakdowns:
        )
        LesliAudit::TrafficSnapshotImporter.call(
            account: audit_account,
            snapshot:
        )
    end
end
