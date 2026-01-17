module LesliAudit
    class AccountLog < ApplicationRecord
        belongs_to :account, optional: true
        belongs_to :user, class_name: "Lesli::User", optional: true
        
        enum :operation, { 
            :account_creation => 'account_creation',
            :account_initialization => 'account_initialization'
        }
    end
end
