module LesliAudit
    class UserJournal < ApplicationRecord
        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :user_journals

        belongs_to :user,
            class_name: "Lesli::User",
            inverse_of: :journals,
            optional: true

        validates :event_uid, presence: true
        validates :request_controller, :request_action, presence: true, if: :retain?

        scope :pending, -> { where(processed_at: nil) }
        scope :processed, -> { where.not(processed_at: nil) }
        scope :retained, -> { where(retain: true) }
        scope :transient, -> { where(retain: false) }
    end
end
