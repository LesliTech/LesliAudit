module LesliAudit
    class UserRequest < ApplicationRecord
        belongs_to :account
        belongs_to :user, class_name: "Lesli::User"
        belongs_to :session, class_name: "Lesli::User::Session"
    end
end
