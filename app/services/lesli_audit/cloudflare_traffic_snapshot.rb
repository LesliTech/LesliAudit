require "uri"

module LesliAudit
    # Immutable input contract for one complete Cloudflare traffic snapshot.
    # Query strings, fragments, credentials, and referrer paths are discarded
    # before any value reaches the database.
    class CloudflareTrafficSnapshot
        BREAKDOWNS_OMITTED = Object.new.freeze
        PROVIDER = "cloudflare".freeze
        MAX_IDENTIFIER_LENGTH = 255

        DEVICE_ALIASES = {
            "phone" => "mobile",
            "smartphone" => "mobile",
            "pc" => "desktop"
        }.freeze

        attr_reader :breakdowns, :date, :hostname, :page_views, :path,
            :resource_id, :resource_type, :snapshot_at, :visits

        def initialize(hostname:, path:, resource_type:, resource_id:, date:,
            page_views:, visits:, snapshot_at:, breakdowns: BREAKDOWNS_OMITTED)
            @hostname = normalize_hostname(hostname).freeze
            @path = normalize_path(path).freeze
            @resource_type = normalize_text(resource_type, :resource_type).freeze
            @resource_id = normalize_positive_integer(resource_id, :resource_id)
            @date = normalize_date(date)
            @page_views = normalize_count(page_views, :page_views)
            @visits = normalize_count(visits, :visits)
            @snapshot_at = normalize_time(snapshot_at)
            @breakdowns_provided = !breakdowns.equal?(BREAKDOWNS_OMITTED)
            @breakdowns = @breakdowns_provided ? normalize_breakdowns(breakdowns) : [].freeze
            freeze
        end

        def provider
            PROVIDER
        end

        def breakdowns_provided?
            @breakdowns_provided
        end

        private

        def normalize_hostname(value)
            raw_hostname = normalize_text(value, :hostname)
            uri = URI.parse(raw_hostname.match?(%r{\Ahttps?://}i) ? raw_hostname : "//#{raw_hostname}")
            raise ArgumentError, "hostname must not include credentials" if uri.userinfo.present?

            hostname = uri.host.to_s.downcase.delete_suffix(".")
            valid = hostname.present? && hostname.length <= MAX_IDENTIFIER_LENGTH
            valid &&= hostname.match?(/\A[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\z/)
            valid &&= !hostname.include?("..")
            raise ArgumentError, "hostname must be a valid DNS hostname" unless valid

            hostname
        rescue URI::InvalidURIError
            raise ArgumentError, "hostname must be a valid DNS hostname"
        end

        def normalize_path(value)
            raw_path = normalize_text(value, :path)
            raw_path = URI.parse(raw_path).path if raw_path.match?(%r{\Ahttps?://}i)
            path = raw_path.to_s.split(/[?#]/, 2).first.to_s
            path = "/#{path}" unless path.start_with?("/")
            path = path.gsub(%r{/+}, "/")
            path = path.delete_suffix("/") unless path == "/"

            valid = path.length <= MAX_IDENTIFIER_LENGTH && !path.match?(/[[:cntrl:]]/)
            raise ArgumentError, "path must be a valid URL path" unless valid

            path
        rescue URI::InvalidURIError
            raise ArgumentError, "path must be a valid URL path"
        end

        def normalize_breakdowns(value)
            rows = Array.wrap(value).map do |attributes|
                attributes = attributes.to_h.symbolize_keys
                dimension = attributes.fetch(:dimension).to_s.strip.downcase
                {
                    dimension: dimension.freeze,
                    value: normalize_breakdown_value(dimension, attributes.fetch(:value)).freeze,
                    page_views: normalize_count(attributes.fetch(:page_views), :page_views),
                    visits: normalize_count(attributes.fetch(:visits), :visits)
                }.freeze
            rescue KeyError, NoMethodError
                raise ArgumentError, "each breakdown must include dimension, value, page_views, and visits"
            end

            keys = rows.map { |row| [ row[:dimension], row[:value] ] }
            raise ArgumentError, "breakdowns must be unique after normalization" if keys.uniq.length != keys.length

            rows.freeze
        end

        def normalize_breakdown_value(dimension, value)
            unless TrafficBreakdown::DIMENSIONS.include?(dimension)
                raise ArgumentError, "unsupported breakdown dimension: #{dimension}"
            end

            case dimension
            when "country"
                normalize_country(value)
            when "device"
                normalize_device(value)
            when "referrer"
                normalize_referrer(value)
            else
                normalize_label(value, dimension)
            end
        end

        def normalize_country(value)
            country = normalize_label(value, :country).upcase
            raise ArgumentError, "country must be a two-character code" unless country.match?(/\A[A-Z0-9]{2}\z/)

            country
        end

        def normalize_device(value)
            device = normalize_label(value, :device)
            DEVICE_ALIASES.fetch(device, device)
        end

        def normalize_referrer(value)
            referrer = value.to_s.strip
            return "direct" if referrer.blank? || %w[(direct) direct none].include?(referrer.downcase)

            uri = URI.parse(referrer.match?(%r{\Ahttps?://}i) ? referrer : "//#{referrer}")
            return normalize_hostname(uri.host) if uri.host.present?

            normalize_label(referrer.split(%r{[/?#]}, 2).first, :referrer)
        rescue URI::InvalidURIError
            raise ArgumentError, "referrer must be a hostname or HTTP URL"
        end

        def normalize_label(value, name)
            normalize_text(value, name).squish.downcase
        end

        def normalize_text(value, name)
            text = value.to_s.strip
            valid = text.present? && text.length <= MAX_IDENTIFIER_LENGTH
            valid &&= !text.match?(/[[:cntrl:]]/)
            raise ArgumentError, "#{name} must be present" unless valid

            text
        end

        def normalize_positive_integer(value, name)
            number = Integer(value)
            raise ArgumentError if number <= 0

            number
        rescue ArgumentError, TypeError
            raise ArgumentError, "#{name} must be a positive integer"
        end

        def normalize_count(value, name)
            count = Integer(value)
            raise ArgumentError if count.negative?

            count
        rescue ArgumentError, TypeError
            raise ArgumentError, "#{name} must be a nonnegative integer"
        end

        def normalize_date(value)
            value.to_date
        rescue NoMethodError, Date::Error
            raise ArgumentError, "date must be date-like"
        end

        def normalize_time(value)
            value.in_time_zone
        rescue NoMethodError, ArgumentError
            raise ArgumentError, "snapshot_at must be time-like"
        end
    end
end
