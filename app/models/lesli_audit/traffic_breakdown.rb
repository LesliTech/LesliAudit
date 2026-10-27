module LesliAudit
    class TrafficBreakdown < ApplicationRecord
        DIMENSIONS = %w[country device browser operating_system referrer].freeze

        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :traffic_breakdowns

        belongs_to :traffic_rollup,
            class_name: "LesliAudit::TrafficRollup",
            inverse_of: :traffic_breakdowns

        before_validation :normalize_dimension

        validates :dimension, inclusion: { in: DIMENSIONS }
        validates :value, presence: true
        validates :value,
            uniqueness: { scope: %i[account_id traffic_rollup_id dimension] }
        validates :page_views, :visits,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

        validate :rollup_belongs_to_account

        private

        def normalize_dimension
            self.dimension = dimension.to_s.strip.downcase.presence
            self.value = value.to_s.strip.presence
        end

        def rollup_belongs_to_account
            return if account_id.blank? || traffic_rollup.blank?
            return if traffic_rollup.account_id == account_id

            errors.add(:traffic_rollup, "must belong to the same account")
        end
    end
end
