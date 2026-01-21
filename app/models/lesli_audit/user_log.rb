module LesliAudit
    class UserLog < ApplicationRecord
        belongs_to :account
        belongs_to :user, class_name: "Lesli::User"
        belongs_to :session, class_name: "LesliShield::User::Session"
        
        enum :operation, { 
            user_creation: 'user_creation',
            session_creation: 'session_creation'
        }
    end
end
