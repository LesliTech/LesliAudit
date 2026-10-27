module LesliAudit
    class VisitorRollup < ApplicationRecord
        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :visitor_rollups

        has_many :visitor_breakdowns,
            inverse_of: :visitor_rollup,
            dependent: :delete_all

        before_validation :normalize_identifiers

        validates :provider,
            presence: true,
            format: { with: /\A[a-z][a-z0-9_-]*\z/ }
        validates :provider_key, :resource_type, :date, :synced_at, presence: true
        validates :resource_id,
            numericality: { only_integer: true, greater_than: 0 }
        validates :provider_key,
            uniqueness: { scope: %i[account_id provider date] }
        validates :page_views, :visits,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

        private

        def normalize_identifiers
            self.provider = provider.to_s.strip.downcase.presence
            self.provider_key = provider_key.to_s.strip.presence
            self.resource_type = resource_type.to_s.strip.presence
        end
    end
end
