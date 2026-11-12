require "test_helper"

module LesliAudit::Cloudflare
  class GraphqlClientTest < ActiveSupport::TestCase
    Response = Struct.new(:code, :body, :headers) do
      def [](name)
        headers[name]
      end
    end

    class ScriptedTransport
      attr_reader :requests

      def initialize(responses)
        @responses = responses
        @requests = []
      end

      def call(**request)
        requests << request
        @responses.shift || raise("Unexpected Cloudflare request")
      end
    end

    test "loads every page and supported breakdown without making a real request" do
      transport = ScriptedTransport.new([
        fixture_response("settings"),
        fixture_response("totals_page_1"),
        fixture_response("totals_page_2"),
        fixture_response("countries"),
        fixture_response("devices"),
        fixture_response("referrers")
      ])
      client = GraphqlClient.new(token: "secret-token", page_size: 10, transport:)

      result = client.traffic(
        zone_id: "zone-123",
        hostname: "example.com",
        date: Date.new(2026, 10, 28)
      )

      assert_equal 3, result.totals.length
      assert_equal [ "/demo/cafe", "/demo/tea", "/pricing" ], result.totals.pluck(:path)
      assert_equal %w[country device referrer], result.breakdowns.pluck(:dimension)
      assert_equal "Bearer secret-token", transport.requests.first[:headers]["Authorization"]
      assert_equal GraphqlClient::ENDPOINT, transport.requests.first[:uri]

      second_totals_request = JSON.parse(transport.requests[2][:body])
      assert_equal "/demo/tea", second_totals_request.dig(
        "variables", "filter", "clientRequestPath_gt"
      )
    end

    test "retries transient responses and honors Retry-After" do
      transport = ScriptedTransport.new([
        response(429, { errors: [ { message: "rate limited" } ] }, "Retry-After" => "4"),
        fixture_response("settings"),
        empty_groups_response,
        empty_groups_response,
        empty_groups_response,
        empty_groups_response
      ])
      waits = []
      client = GraphqlClient.new(
        token: "secret-token",
        transport:,
        sleeper: ->(seconds) { waits << seconds }
      )

      result = client.traffic(
        zone_id: "zone-123",
        hostname: "example.com",
        date: Date.new(2026, 10, 28)
      )

      assert_empty result.totals
      assert_equal [ 4 ], waits
      assert_equal 6, transport.requests.length
    end

    test "does not retry authentication or query errors" do
      transport = ScriptedTransport.new([
        response(403, { errors: [ { message: "forbidden" } ] })
      ])
      waits = []
      client = GraphqlClient.new(
        token: "invalid-token",
        transport:,
        sleeper: ->(seconds) { waits << seconds }
      )

      error = assert_raises(GraphqlClient::Error) do
        client.traffic(
          zone_id: "zone-123",
          hostname: "example.com",
          date: Date.new(2026, 10, 28)
        )
      end

      assert_match "authentication failed", error.message
      assert_empty waits
      assert_equal 1, transport.requests.length
    end

    test "queries only dimensions exposed by the zone settings" do
      settings = response(200, data: {
        viewer: {
          zones: [ {
            settings: {
              httpRequestsAdaptiveGroups: {
                enabled: true,
                availableFields: %w[
                  count
                  sum_visits
                  dimensions_clientRequestPath
                  dimensions_clientCountryName
                  dimensions_clientDeviceType
                ],
                maxPageSize: 100
              }
            }
          } ]
        }
      })
      transport = ScriptedTransport.new([
        settings,
        empty_groups_response,
        empty_groups_response,
        empty_groups_response
      ])
      client = GraphqlClient.new(token: "secret-token", transport:)

      client.traffic(
        zone_id: "zone-123",
        hostname: "example.com",
        date: Date.new(2026, 10, 28)
      )

      queries = transport.requests.map { |request| JSON.parse(request[:body]).fetch("query") }
      assert_equal 4, queries.length
      assert_not queries.any? { |query| query.include?("clientRefererHost") }
    end

    private

    def fixture_response(name)
      body = LesliAudit::Engine.root
        .join("test/fixtures/files/cloudflare/#{name}.json")
        .read
      Response.new("200", body, {})
    end

    def empty_groups_response
      response(200, data: { viewer: { zones: [ { groups: [] } ] } })
    end

    def response(status, payload, headers = {})
      Response.new(status.to_s, JSON.generate(payload), headers)
    end
  end
end
