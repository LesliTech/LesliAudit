module LesliAudit::Cloudflare
  class Configuration
    class Invalid < StandardError; end

    DEFAULTS = {
      enabled: false,
      hostnames: [],
      account_ids: [],
      page_size: 1_000,
      max_pages: 100,
      backfill_days: 30,
      reimport_days: 3,
      resource_resolver: ->(**) { nil }
    }.freeze

    attr_reader :account_ids, :backfill_days, :hostnames, :max_pages,
      :page_size, :reimport_days, :resource_resolver, :zone_id

    def self.from_application
      settings = DEFAULTS.merge(Lesli.config.audit.fetch(:cloudflare, {}))

      new(
        enabled: settings[:enabled],
        token: credentials_token.presence || ENV["CLOUDFLARE_ANALYTICS_TOKEN"],
        zone_id: settings[:zone_id],
        hostnames: settings[:hostnames],
        account_ids: settings[:account_ids],
        page_size: settings[:page_size],
        max_pages: settings[:max_pages],
        backfill_days: settings[:backfill_days],
        reimport_days: settings[:reimport_days],
        resource_resolver: settings[:resource_resolver]
      )
    end

    def self.credentials_token
      Rails.application.credentials.dig(:cloudflare, :analytics, :token)
    end
    private_class_method :credentials_token

    def initialize(enabled:, token:, zone_id:, hostnames:, account_ids:,
      page_size:, max_pages:, backfill_days:, reimport_days:, resource_resolver:)
      @enabled = ActiveModel::Type::Boolean.new.cast(enabled)
      @token = token.to_s.strip.presence
      @zone_id = zone_id.to_s.strip.presence
      @hostnames = Array(hostnames)
        .filter_map { |value| value.to_s.strip.downcase.presence }
        .uniq
      @account_ids = normalize_account_ids(account_ids)
      @page_size = positive_integer(page_size, :page_size)
      @max_pages = positive_integer(max_pages, :max_pages)
      @backfill_days = positive_integer(backfill_days, :backfill_days)
      @reimport_days = positive_integer(reimport_days, :reimport_days)
      @resource_resolver = resource_resolver
    end

    def enabled?
      @enabled
    end

    def token
      @token
    end

    def validate!
      raise Invalid, "Cloudflare analytics token is missing" if token.blank?
      raise Invalid, "Cloudflare zone ID is missing" if zone_id.blank?
      raise Invalid, "At least one Cloudflare hostname is required" if hostnames.empty?
      raise Invalid, "resource_resolver must be callable" unless resource_resolver.respond_to?(:call)

      self
    end

    private

    def normalize_account_ids(values)
      Array(values).filter_map do |value|
        id = Integer(value, exception: false)
        id if id&.positive?
      end.uniq
    end

    def positive_integer(value, name)
      number = Integer(value)
      raise ArgumentError unless number.positive?

      number
    rescue ArgumentError, TypeError
      raise Invalid, "#{name} must be a positive integer"
    end
  end
end
