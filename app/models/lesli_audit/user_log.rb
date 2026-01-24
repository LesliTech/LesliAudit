module LesliAudit
    class UserLog < ApplicationRecord
        belongs_to :account
        belongs_to :user, class_name: "Lesli::User"
        belongs_to :session, class_name: "LesliShield::User::Session", optional: true
        
        enum :operation, { 
            user_creation: 'user_creation',
            session_creation: 'session_creation',
            authorize_request: 'authorize_request'
        }
    end
end
