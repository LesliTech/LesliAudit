module LesliAudit
  class CloudflareTrafficSyncJob < ApplicationJob
    queue_as :default

    def self.enqueue_recent(configuration: Cloudflare::Configuration.from_application)
      return unless configuration.enabled?

      configuration.validate!
      if configuration.account_ids.empty?
        raise Cloudflare::Configuration::Invalid,
          "At least one account ID is required for scheduled synchronization"
      end

      configuration.account_ids.each { |account_id| perform_later(account_id) }
    end

    def self.enqueue_backfill(account_id, days: nil,
      configuration: Cloudflare::Configuration.from_application)
      configuration.validate!
      days = Integer(days || configuration.backfill_days)
      raise ArgumentError, "days must be positive" unless days.positive?

      end_on = Date.yesterday
      start_on = end_on - (days - 1).days
      perform_later(account_id, start_on:, end_on:)
    end

    def perform(account_id, start_on: nil, end_on: nil)
      configuration = traffic_configuration
      return unless configuration.enabled?

      configuration.validate!
      core_account = Lesli::Account.find(account_id)
      audit_account = LesliAudit::Account.find_by!(account_id: core_account.id)
      start_on, end_on = period(configuration, start_on:, end_on:)
      sync = find_sync(audit_account, configuration, start_on, end_on)
      execution_id = sync.acquire!
      return unless execution_id

      result = sync_service(configuration).call(
        account: core_account,
        start_on:,
        end_on:
      )
      sync.complete!(execution_id:, snapshots_count: result.snapshots_count)
    rescue => error
      sync&.fail!(execution_id:, error:) if execution_id
      raise
    end

    private

    def traffic_configuration
      Cloudflare::Configuration.from_application
    end

    def sync_service(configuration)
      Cloudflare::SyncService.new(configuration:)
    end

    def period(configuration, start_on:, end_on:)
      end_on = end_on&.to_date || Date.yesterday
      start_on = start_on&.to_date || end_on - (configuration.reimport_days - 1).days
      raise ArgumentError, "end_on must be on or after start_on" if end_on < start_on

      [ start_on, end_on ]
    end

    def find_sync(account, configuration, start_on, end_on)
      CloudflareTrafficSync.create_or_find_by!(
        account:,
        zone_id: configuration.zone_id,
        period_start: start_on,
        period_end: end_on
      )
    end
  end
end
