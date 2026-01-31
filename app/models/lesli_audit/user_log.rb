module LesliAudit
    class UserLog < ApplicationRecord
        belongs_to :account, optional: true
        belongs_to :user, class_name: "Lesli::User"
        belongs_to :session, class_name: "LesliShield::User::Session", optional: true
    end
end
