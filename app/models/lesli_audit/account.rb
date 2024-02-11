module LesliAudit
    class Account < ApplicationRecord
        belongs_to :account, class_name: "Lesli::Account"
        has_many :account_requests
        has_many :user_requests
        has_many :dashboards

        after_create :initialize_account

        def initialize_account
            Dashboard.initialize_account(self)
        end
    end
end
