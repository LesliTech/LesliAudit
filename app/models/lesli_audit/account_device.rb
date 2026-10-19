module LesliAudit
    class AccountDevice < ApplicationRecord
        belongs_to :account
    end
end
