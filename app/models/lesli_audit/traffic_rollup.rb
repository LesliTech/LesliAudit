module LesliAudit
    class TrafficRollup < ApplicationRecord
        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :traffic_rollups

        has_many :traffic_breakdowns,
            inverse_of: :traffic_rollup,
            dependent: :delete_all

        before_validation :normalize_identifiers

        validates :provider,
            presence: true,
            format: { with: /\A[a-z][a-z0-9_-]*\z/ }
        validates :hostname, :path, :resource_type, :date, :snapshot_at, presence: true
        validates :resource_id,
            numericality: { only_integer: true, greater_than: 0 }
        validates :path,
            uniqueness: { scope: %i[account_id provider hostname date] }
        validates :page_views, :visits,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

        private

        def normalize_identifiers
            self.provider = provider.to_s.strip.downcase.presence
            self.hostname = hostname.to_s.strip.downcase.presence
            self.path = path.to_s.strip.presence
            self.resource_type = resource_type.to_s.strip.presence
        end
    end
end
