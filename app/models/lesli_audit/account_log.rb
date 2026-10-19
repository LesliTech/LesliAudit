module LesliAudit
    class AccountLog < ApplicationRecord
        include LesliAudit::AppendOnly

        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :account_logs

        belongs_to :user,
            class_name: "Lesli::User",
            inverse_of: :account_logs,
            optional: true

        validates :operation, presence: true
    end
end
