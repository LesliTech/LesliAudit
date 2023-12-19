module LesliAudit
    class Account < ApplicationRecord
        belongs_to :account, class_name: "Lesli::Account"
        has_many :account_requests
        has_many :user_requests
        has_many :dashboards

        after_create :initialize_account

        def initialize_account
            #Workflow.initialize_data(self)
            Dashboard.initialize_data(self)
            #Sla.initialize_data(self)
            #Catalog.initialize_data(self)
            #Account::Setting.initialize_data(self)
        end
    end
end
