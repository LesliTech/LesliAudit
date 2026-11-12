require "test_helper"

module LesliAudit::Cloudflare
  class SyncServiceTest < ActiveSupport::TestCase
    class FakeClient
      attr_reader :calls

      def initialize(traffic_data)
        @traffic_data = traffic_data
        @calls = []
      end

      def traffic(**arguments)
        calls << arguments
        @traffic_data
      end
    end

    test "imports one complete snapshot per mapped path and day" do
      account = create_cloudflare_test_account
      traffic_data = GraphqlClient::TrafficData.new(
        totals: [ { path: "/demo/cafe", page_views: 100, visits: 70 } ],
        breakdowns: [ {
          path: "/demo/cafe",
          dimension: "country",
          value: "GT",
          page_views: 60,
          visits: 42
        } ]
      )
      client = FakeClient.new(traffic_data)
      service = SyncService.new(
        configuration: cloudflare_configuration,
        client:
      )

      result = service.call(
        account:,
        start_on: Date.new(2026, 10, 27),
        end_on: Date.new(2026, 10, 28)
      )

      assert_equal 2, result.snapshots_count
      assert_empty result.ignored_paths
      assert_equal 2, client.calls.length
      assert_equal [ Date.new(2026, 10, 27), Date.new(2026, 10, 28) ], client.calls.pluck(:date)

      rollups = account.audit.traffic_rollups.order(:date)
      assert_equal 2, rollups.count
      assert_equal [ 100, 100 ], rollups.pluck(:page_views)
      assert_equal [ "GT" ], rollups.last.traffic_breakdowns.pluck(:value)
    end

    test "does not partially import a hostname and day" do
      account = create_cloudflare_test_account
      traffic_data = GraphqlClient::TrafficData.new(
        totals: [
          { path: "/demo/one", page_views: 100, visits: 70 },
          { path: "/demo/two", page_views: 80, visits: 55 }
        ],
        breakdowns: []
      )
      client = FakeClient.new(traffic_data)
      resolver = lambda do |account:, hostname:, path:|
        resource_id = path == "/demo/one" ? 1 : 0
        { resource_type: "Profile", resource_id: }
      end
      service = SyncService.new(
        configuration: cloudflare_configuration(resource_resolver: resolver),
        client:
      )

      assert_raises(ArgumentError) do
        service.call(
          account:,
          start_on: Date.new(2026, 10, 28),
          end_on: Date.new(2026, 10, 28)
        )
      end

      assert_empty account.audit.traffic_rollups
    end
  end
end
