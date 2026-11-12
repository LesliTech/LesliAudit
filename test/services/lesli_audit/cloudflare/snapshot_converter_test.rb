require "test_helper"

module LesliAudit::Cloudflare
  class SnapshotConverterTest < ActiveSupport::TestCase
    test "builds sanitized snapshots and combines normalized breakdown values" do
      resolver_calls = []
      resolver = lambda do |account:, hostname:, path:|
        resolver_calls << { account:, hostname:, path: }
        { resource_type: "Profile", resource_id: 27 }
      end
      traffic_data = GraphqlClient::TrafficData.new(
        totals: [
          { path: "/demo/cafe?utm_source=private#fragment", page_views: 100, visits: 70 }
        ],
        breakdowns: [
          breakdown("device", "smartphone", 30, 20),
          breakdown("device", "phone", 20, 15),
          breakdown("referrer", "https://EXAMPLE.org/article?secret=yes", 10, 8),
          breakdown("referrer", "example.org", 5, 4),
          breakdown("country", "gt", 60, 42)
        ]
      )
      converter = SnapshotConverter.new(resource_resolver: resolver)

      result = converter.call(
        account: :account,
        hostname: "Example.COM",
        date: Date.new(2026, 10, 28),
        traffic_data:,
        snapshot_at: Time.zone.local(2026, 10, 29, 3)
      )

      assert_equal 1, result.snapshots.length
      snapshot = result.snapshots.first
      assert_equal "/demo/cafe", snapshot.path
      assert_equal "example.com", snapshot.hostname
      assert_equal 100, snapshot.page_views
      assert_equal 70, snapshot.visits
      assert_equal({
        account: :account,
        hostname: "Example.COM",
        path: "/demo/cafe"
      }, resolver_calls.first)
      assert_equal({ page_views: 50, visits: 35 }, totals_for(snapshot, "device", "mobile"))
      assert_equal({ page_views: 15, visits: 12 }, totals_for(snapshot, "referrer", "example.org"))
      assert_equal({ page_views: 60, visits: 42 }, totals_for(snapshot, "country", "GT"))
    end

    test "reports paths that the host does not map to a resource" do
      data = GraphqlClient::TrafficData.new(
        totals: [ { path: "/unknown", page_views: 10, visits: 7 } ],
        breakdowns: []
      )
      converter = SnapshotConverter.new(resource_resolver: ->(**) { nil })

      result = converter.call(
        account: :account,
        hostname: "example.com",
        date: Date.new(2026, 10, 28),
        traffic_data: data
      )

      assert_empty result.snapshots
      assert_equal [ "/unknown" ], result.ignored_paths
    end

    private

    def breakdown(dimension, value, page_views, visits)
      {
        path: "/demo/cafe?utm_source=private#fragment",
        dimension:,
        value:,
        page_views:,
        visits:
      }
    end

    def totals_for(snapshot, dimension, value)
      row = snapshot.breakdowns.find do |breakdown|
        breakdown[:dimension] == dimension && breakdown[:value] == value
      end
      row.slice(:page_views, :visits)
    end
  end
end
