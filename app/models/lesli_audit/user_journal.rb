module LesliAudit
    class UserJournal < ApplicationRecord
        belongs_to :account
        belongs_to :user, class_name: "Lesli::User"
        belongs_to :session, class_name: "LesliShield::User::Session"
    end
end
