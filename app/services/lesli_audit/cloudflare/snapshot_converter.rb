require "uri"

module LesliAudit::Cloudflare
  class SnapshotConverter
    Result = Data.define(:snapshots, :ignored_paths)

    def initialize(resource_resolver:)
      @resource_resolver = resource_resolver
    end

    def call(account:, hostname:, date:, traffic_data:, snapshot_at: Time.current)
      ignored_paths = []
      snapshots = traffic_data.totals.filter_map do |totals|
        path = normalize_path(totals[:path])
        resource = resolve_resource(account:, hostname:, path:)
        unless resource
          ignored_paths << path
          next
        end

        LesliAudit::CloudflareTrafficSnapshot.new(
          hostname:,
          path:,
          resource_type: resource.fetch(:resource_type),
          resource_id: resource.fetch(:resource_id),
          date:,
          page_views: totals[:page_views],
          visits: totals[:visits],
          snapshot_at:,
          breakdowns: breakdowns_for(traffic_data.breakdowns, path)
        )
      end

      Result.new(snapshots:, ignored_paths: ignored_paths.uniq)
    end

    private

    attr_reader :resource_resolver

    def resolve_resource(account:, hostname:, path:)
      resource = resource_resolver.call(account:, hostname:, path:)
      return if resource.nil?

      resource.to_h.symbolize_keys
    rescue NoMethodError
      raise ArgumentError, "resource_resolver must return a hash or nil"
    end

    def breakdowns_for(rows, path)
      # Different Cloudflare labels can normalize to the same LesliAudit value,
      # so their totals are combined before one snapshot is created.
      grouped = Hash.new { |hash, key| hash[key] = { page_views: 0, visits: 0 } }

      rows.each do |row|
        next unless normalize_path(row[:path]) == path

        value = normalize_breakdown_value(row[:dimension], row[:value])
        next unless value

        totals = grouped[[ row[:dimension], value ]]
        totals[:page_views] += row[:page_views]
        totals[:visits] += row[:visits]
      end

      grouped.map do |(dimension, value), totals|
        { dimension:, value:, **totals }
      end
    end

    def normalize_breakdown_value(dimension, value)
      case dimension
      when "country"
        country = value.to_s.strip.upcase
        country if country.match?(/\A[A-Z0-9]{2}\z/)
      when "device"
        device = value.to_s.strip.downcase.presence || "unknown"
        LesliAudit::CloudflareTrafficSnapshot::DEVICE_ALIASES.fetch(device, device)
      when "referrer"
        normalize_referrer(value)
      end
    end

    def normalize_path(value)
      path = value.to_s.split(/[?#]/, 2).first.to_s
      path = "/#{path}" unless path.start_with?("/")
      path = path.gsub(%r{/+}, "/")
      path == "/" ? path : path.delete_suffix("/")
    end

    def normalize_referrer(value)
      referrer = value.to_s.strip
      return "direct" if referrer.blank?

      uri = URI.parse(referrer.match?(%r{\Ahttps?://}i) ? referrer : "//#{referrer}")
      uri.host.to_s.downcase.delete_suffix(".").presence
    rescue URI::InvalidURIError
      nil
    end
  end
end
