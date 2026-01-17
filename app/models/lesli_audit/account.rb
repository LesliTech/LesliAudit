module LesliAudit
    class Account < ApplicationRecord
        belongs_to :account, class_name: "Lesli::Account"
        has_many :dashboards

        has_many :account_logs
        has_many :account_devices
        has_many :account_requests

        has_many :user_logs
        has_many :user_journals
        has_many :user_requests

        after_create :initialize_account

        def initialize_account
        end
    end
end
