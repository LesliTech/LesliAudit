module LesliAudit
    class Account < ApplicationRecord
        belongs_to :account, class_name: "Lesli::Account"
        has_many :dashboards

        has_many :logs
        has_many :user_requests
        has_many :account_requests
        has_many :devices
        
        

        after_create :initialize_account

        def initialize_account
        end
    end
end
