module LesliAudit
    class AccountLog < ApplicationRecord
        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :account_logs

        belongs_to :user,
            class_name: "Lesli::User",
            inverse_of: :account_logs,
            optional: true
        
        enum :operation, { 
            :account_creation => 'account_creation',
            :account_initialization => 'account_initialization'
        }
    end
end
