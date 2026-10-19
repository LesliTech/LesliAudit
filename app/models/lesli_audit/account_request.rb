module LesliAudit
    class AccountRequest < ApplicationRecord
        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :account_requests
    end
end
