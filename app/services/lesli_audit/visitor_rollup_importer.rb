module LesliAudit
    # Imports one complete provider snapshot for a public resource and day.
    #
    # Counts are replaced rather than incremented so a provider synchronization
    # can safely repeat after partial data has settled. Breakdown rows omitted
    # from a later snapshot are removed within the same transaction.
    class VisitorRollupImporter
        class ResourceConflict < StandardError; end

        def self.call(account:, provider:, provider_key:, resource_type:, resource_id:,
            date:, page_views:, visits:, breakdowns: [], synced_at: Time.current)
            new(
                account:,
                provider:,
                provider_key:,
                resource_type:,
                resource_id:,
                date:,
                page_views:,
                visits:,
                breakdowns:,
                synced_at:
            ).call
        end

        def initialize(account:, provider:, provider_key:, resource_type:, resource_id:,
            date:, page_views:, visits:, breakdowns:, synced_at:)
            @account = account
            @provider = normalize_identifier(provider, :provider).downcase
            @provider_key = normalize_identifier(provider_key, :provider_key)
            @resource_type = normalize_identifier(resource_type, :resource_type)
            @resource_id = normalize_positive_integer(resource_id, :resource_id)
            @date = normalize_date(date)
            @page_views = normalize_count(page_views, :page_views)
            @visits = normalize_count(visits, :visits)
            @breakdowns = normalize_breakdowns(breakdowns)
            @synced_at = synced_at
        end

        def call
            raise ArgumentError, "account must be a persisted LesliAudit::Account" unless valid_account?

            account.transaction do
                rollup = account.visitor_rollups.find_or_initialize_by(
                    provider:,
                    provider_key:,
                    date:
                )
                ensure_resource_matches!(rollup) if rollup.persisted?
                rollup.assign_attributes(
                    resource_type:,
                    resource_id:,
                    page_views:,
                    visits:,
                    synced_at:
                )
                rollup.save!

                replace_breakdowns(rollup)
                rollup
            end
        end

        private

        attr_reader :account, :breakdowns, :date, :page_views, :provider,
            :provider_key, :resource_id, :resource_type, :synced_at, :visits

        def valid_account?
            account.is_a?(LesliAudit::Account) && account.persisted?
        end

        def normalize_identifier(value, name)
            identifier = value.to_s.strip
            raise ArgumentError, "#{name} must be present" if identifier.blank?

            identifier
        end

        def normalize_positive_integer(value, name)
            number = Integer(value)
            raise ArgumentError if number <= 0

            number
        rescue ArgumentError, TypeError
            raise ArgumentError, "#{name} must be a positive integer"
        end

        def normalize_date(value)
            value.to_date
        rescue NoMethodError, Date::Error
            raise ArgumentError, "date must be date-like"
        end

        def normalize_count(value, name)
            count = Integer(value)
            raise ArgumentError if count.negative?

            count
        rescue ArgumentError, TypeError
            raise ArgumentError, "#{name} must be a nonnegative integer"
        end

        def normalize_breakdowns(value)
            rows = Array.wrap(value).map do |attributes|
                attributes = attributes.to_h.symbolize_keys
                {
                    dimension: attributes.fetch(:dimension).to_s.strip.downcase,
                    value: attributes.fetch(:value).to_s.strip,
                    page_views: normalize_count(attributes.fetch(:page_views), :page_views),
                    visits: normalize_count(attributes.fetch(:visits), :visits)
                }
            rescue KeyError, NoMethodError
                raise ArgumentError, "each breakdown must include dimension, value, page_views, and visits"
            end

            keys = rows.map { |row| [row[:dimension], row[:value]] }
            raise ArgumentError, "breakdowns must be unique by dimension and value" if keys.uniq.length != keys.length

            rows
        end

        def ensure_resource_matches!(rollup)
            return if rollup.resource_type == resource_type && rollup.resource_id == resource_id

            raise ResourceConflict,
                "provider key is already attributed to another resource for this date"
        end

        def replace_breakdowns(rollup)
            kept_ids = breakdowns.map do |attributes|
                breakdown = rollup.visitor_breakdowns.find_or_initialize_by(
                    account:,
                    dimension: attributes[:dimension],
                    value: attributes[:value]
                )
                breakdown.assign_attributes(
                    page_views: attributes[:page_views],
                    visits: attributes[:visits]
                )
                breakdown.save!
                breakdown.id
            end

            stale = rollup.visitor_breakdowns
            stale = stale.where.not(id: kept_ids) if kept_ids.any?
            stale.delete_all
        end
    end
end
