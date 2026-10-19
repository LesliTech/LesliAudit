module LesliAudit
    class AccountDevice < ApplicationRecord
        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :account_devices
    end
end
