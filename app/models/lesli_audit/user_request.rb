module LesliAudit
    class UserRequest < ApplicationRecord
        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :user_requests

        belongs_to :user,
            class_name: "Lesli::User",
            inverse_of: :requests
    end
end
