module LesliAudit
    class UserLog < ApplicationRecord
        belongs_to :account
        belongs_to :user, class_name: "Lesli::User"
        
        enum :operation, { 
            user_creation: 'user_creation',
            session_creation: 'session_creation'
        }
    end
end
