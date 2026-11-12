module LesliAudit::Cloudflare
  class SyncService
    class MissingAuditAccount < StandardError; end

    Result = Data.define(:snapshots_count, :ignored_paths)

    def initialize(configuration: Configuration.from_application, client: nil,
      converter: nil)
      @configuration = configuration.validate!
      @client = client || GraphqlClient.new(
        token: configuration.token,
        page_size: configuration.page_size,
        max_pages: configuration.max_pages
      )
      @converter = converter || SnapshotConverter.new(
        resource_resolver: configuration.resource_resolver
      )
    end

    def call(account:, start_on:, end_on:)
      start_on = start_on.to_date
      end_on = end_on.to_date
      raise ArgumentError, "end_on must be on or after start_on" if end_on < start_on

      audit_account = LesliAudit::Account.find_by(account_id: account.id)
      raise MissingAuditAccount, "LesliAudit is not enabled for account #{account.id}" unless audit_account

      snapshots_count = 0
      ignored_paths = []

      (start_on..end_on).each do |date|
        configuration.hostnames.each do |hostname|
          imported = import_day(
            account:,
            audit_account:,
            hostname:,
            date:
          )
          snapshots_count += imported.snapshots.length
          ignored_paths.concat(imported.ignored_paths)
        end
      end

      Result.new(snapshots_count:, ignored_paths: ignored_paths.uniq)
    end

    private

    attr_reader :client, :configuration, :converter

    def import_day(account:, audit_account:, hostname:, date:)
      traffic_data = client.traffic(
        zone_id: configuration.zone_id,
        hostname:,
        date:
      )
      converted = converter.call(
        account:,
        hostname:,
        date:,
        traffic_data:,
        snapshot_at: Time.current
      )

      # Network work is complete before opening the transaction. This keeps the
      # lock short while making every resource for this hostname/day coherent.
      LesliAudit::TrafficRollup.transaction do
        converted.snapshots.each do |snapshot|
          LesliAudit::TrafficSnapshotImporter.call(
            account: audit_account,
            snapshot:
          )
        end
      end

      converted
    end
  end
end
