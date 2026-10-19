module LesliAudit
    class UserLog < ApplicationRecord
        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :user_logs

        belongs_to :user,
            class_name: "Lesli::User",
            inverse_of: :logs,
            optional: true
    end
end
