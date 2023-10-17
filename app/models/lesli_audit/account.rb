module LesliAudit
    class Account < ApplicationRecord
        has_many :account_requests
        has_many :user_requests
    end
end
