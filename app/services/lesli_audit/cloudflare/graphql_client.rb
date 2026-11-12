require "json"
require "net/http"

module LesliAudit::Cloudflare
  class GraphqlClient
    ENDPOINT = URI("https://api.cloudflare.com/client/v4/graphql")
    TRANSIENT_HTTP_STATUSES = [ 429, 500, 502, 503, 504 ].freeze
    TRANSIENT_GRAPHQL_ERROR = /rate.?limit|temporar|timeout|try again|unavailable|internal server/i
    TRANSIENT_GRAPHQL_CODES = %w[
      INTERNAL_SERVER_ERROR
      RATE_LIMITED
      SERVICE_UNAVAILABLE
      TIMEOUT
    ].freeze
    NETWORK_ERRORS = [
      Net::OpenTimeout,
      Net::ReadTimeout,
      EOFError,
      Errno::ECONNRESET,
      Errno::ETIMEDOUT
    ].freeze

    DIMENSIONS = {
      country: "clientCountryName",
      device: "clientDeviceType",
      referrer: "clientRefererHost"
    }.freeze

    TrafficData = Data.define(:totals, :breakdowns)

    class Error < StandardError; end

    class TransientError < Error
      attr_reader :retry_after

      def initialize(message, retry_after: nil)
        @retry_after = retry_after
        super(message)
      end
    end

    class HttpTransport
      OPEN_TIMEOUT = 10
      READ_TIMEOUT = 30

      def call(uri:, headers:, body:)
        request = Net::HTTP::Post.new(uri)
        headers.each { |name, value| request[name] = value }
        request.body = body

        Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: true,
          open_timeout: OPEN_TIMEOUT,
          read_timeout: READ_TIMEOUT
        ) do |http|
          http.request(request)
        end
      end
    end

    def initialize(token:, page_size: 1_000, max_pages: 100, max_retries: 3,
      transport: HttpTransport.new, sleeper: ->(seconds) { sleep(seconds) })
      @token = token.to_s.strip
      @configured_page_size = Integer(page_size)
      @max_pages = Integer(max_pages)
      @max_retries = Integer(max_retries)
      @transport = transport
      @sleeper = sleeper

      validate_configuration!
    end

    def traffic(zone_id:, hostname:, date:)
      page_size = page_size_for(zone_id)
      totals = fetch_groups(zone_id:, hostname:, date:, page_size:)
      breakdowns = supported_dimensions(zone_id).flat_map do |dimension, field|
        fetch_groups(zone_id:, hostname:, date:, page_size:, dimension:, field:)
      end

      TrafficData.new(totals:, breakdowns:)
    end

    private

    attr_reader :configured_page_size, :max_pages, :max_retries,
      :sleeper, :token, :transport

    def validate_configuration!
      raise ArgumentError, "token must be present" if token.empty?
      unless configured_page_size.between?(1, 10_000)
        raise ArgumentError, "page_size must be between 1 and 10,000"
      end
      raise ArgumentError, "max_pages must be positive" unless max_pages.positive?
      raise ArgumentError, "max_retries cannot be negative" if max_retries.negative?
    end

    def page_size_for(zone_id)
      maximum = dataset_settings(zone_id)["maxPageSize"].presence || configured_page_size
      [ configured_page_size, Integer(maximum) ].min
    end

    def supported_dimensions(zone_id)
      available_fields = Array(dataset_settings(zone_id)["availableFields"])
      return DIMENSIONS if available_fields.empty?

      # Cloudflare plans can expose different fields. Query only dimensions
      # advertised by the zone so an optional breakdown cannot fail the import.
      DIMENSIONS.select do |_dimension, field|
        available_fields.any? { |available| available == field || available.end_with?("_#{field}") }
      end
    end

    def dataset_settings(zone_id)
      @dataset_settings ||= {}
      @dataset_settings[zone_id] ||= load_dataset_settings(zone_id)
    end

    def load_dataset_settings(zone_id)
      data = execute(
        query: <<~GRAPHQL,
          query TrafficSettings($zoneTag: string) {
            viewer {
              zones(filter: { zoneTag: $zoneTag }) {
                settings {
                  httpRequestsAdaptiveGroups {
                    enabled
                    availableFields
                    maxPageSize
                    maxDuration
                    notOlderThan
                  }
                }
              }
            }
          }
        GRAPHQL
        variables: { zoneTag: zone_id }
      )

      zone = extract_zone(data)
      settings = zone.dig("settings", "httpRequestsAdaptiveGroups") || {}
      raise Error, "httpRequestsAdaptiveGroups is not enabled for this zone" if settings["enabled"] == false

      settings
    end

    def fetch_groups(zone_id:, hostname:, date:, page_size:, dimension: nil, field: nil)
      rows = []
      filter = base_filter(hostname, date)

      max_pages.times do
        page = execute_group_query(
          zone_id:,
          filter:,
          page_size:,
          field:
        )
        rows.concat(transform_rows(page, dimension:, field:))
        return rows if page.length < page_size

        filter = base_filter(hostname, date).merge(cursor_filter(page.last, field:))
      end

      raise Error, "Cloudflare result exceeded the configured max_pages limit"
    end

    def execute_group_query(zone_id:, filter:, page_size:, field:)
      dimensions = [ "clientRequestPath", field ].compact.join("\n")
      order = [ "clientRequestPath_ASC", field && "#{field}_ASC" ].compact.join(", ")
      query = <<~GRAPHQL
        query TrafficGroups($zoneTag: string, $filter: filter) {
          viewer {
            zones(filter: { zoneTag: $zoneTag }) {
              groups: httpRequestsAdaptiveGroups(
                filter: $filter
                limit: #{page_size}
                orderBy: [#{order}]
              ) {
                count
                sum { visits }
                dimensions {
                  #{dimensions}
                }
              }
            }
          }
        }
      GRAPHQL

      data = execute(query:, variables: { zoneTag: zone_id, filter: })
      extract_zone(data).fetch("groups", [])
    end

    def base_filter(hostname, date)
      day = date.to_date
      {
        datetime_geq: Time.utc(day.year, day.month, day.day).iso8601,
        datetime_lt: Time.utc(day.next_day.year, day.next_day.month, day.next_day.day).iso8601,
        clientRequestHTTPHost: hostname,
        requestSource: "eyeball"
      }
    end

    # Cloudflare GraphQL has no cursor pagination. A composite cursor preserves
    # rows that share the same path while advancing the secondary dimension.
    def cursor_filter(row, field:)
      path = row.dig("dimensions", "clientRequestPath")
      return { clientRequestPath_gt: path } unless field

      value = row.dig("dimensions", field).to_s
      {
        OR: [
          { clientRequestPath_gt: path },
          { clientRequestPath: path, "#{field}_gt" => value }
        ]
      }
    end

    def transform_rows(rows, dimension:, field:)
      rows.map do |row|
        transformed = {
          path: row.dig("dimensions", "clientRequestPath"),
          page_views: Integer(row.fetch("count", 0)),
          visits: Integer(row.dig("sum", "visits") || 0)
        }
        next transformed unless dimension

        transformed.merge(
          dimension: dimension.to_s,
          value: row.dig("dimensions", field)
        )
      end
    end

    def execute(query:, variables:)
      attempts = 0

      # Permanent GraphQL and authentication errors fail immediately. Only
      # network failures and transient provider responses are safe to retry.
      begin
        response = transport.call(
          uri: ENDPOINT,
          headers: request_headers,
          body: JSON.generate(query:, variables:)
        )
        parse_response(response)
      rescue *NETWORK_ERRORS, TransientError => error
        raise if attempts >= max_retries

        sleeper.call(retry_delay(attempts, error))
        attempts += 1
        retry
      end
    end

    def request_headers
      {
        "Authorization" => "Bearer #{token}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
    end

    def parse_response(response)
      status = Integer(response.code)
      if TRANSIENT_HTTP_STATUSES.include?(status)
        raise TransientError.new(
          "Cloudflare returned HTTP #{status}",
          retry_after: response["Retry-After"]
        )
      end
      raise Error, "Cloudflare authentication failed" if [ 401, 403 ].include?(status)
      raise Error, "Cloudflare returned HTTP #{status}" unless status.between?(200, 299)

      payload = JSON.parse(response.body)
      errors = Array(payload["errors"])
      raise_graphql_error(errors) if errors.any?

      payload.fetch("data")
    rescue JSON::ParserError, KeyError
      raise Error, "Cloudflare returned an invalid GraphQL response"
    end

    def raise_graphql_error(errors)
      message = errors.filter_map { |error| error["message"] }.join("; ").presence ||
        "Cloudflare GraphQL query failed"
      transient = errors.any? do |error|
        code = error.dig("extensions", "code").to_s
        TRANSIENT_GRAPHQL_CODES.include?(code) || error["message"].to_s.match?(TRANSIENT_GRAPHQL_ERROR)
      end
      error_class = transient ? TransientError : Error
      raise error_class, message
    end

    def extract_zone(data)
      zones = data.dig("viewer", "zones")
      raise Error, "Cloudflare response did not include the configured zone" unless zones&.one?

      zones.first
    end

    def retry_delay(attempt, error)
      retry_after = error.respond_to?(:retry_after) && error.retry_after
      Integer(retry_after, exception: false) || (2**attempt)
    end
  end
end
