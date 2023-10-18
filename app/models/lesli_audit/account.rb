module LesliAudit
    class Account < ApplicationRecord
        belongs_to :account, :class_name => "Lesli::Account"
        has_many :account_requests
        has_many :user_requests
    end
end
