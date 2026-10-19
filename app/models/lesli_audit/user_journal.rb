module LesliAudit
    class UserJournal < ApplicationRecord
        belongs_to :account,
            class_name: "LesliAudit::Account",
            inverse_of: :user_journals

        belongs_to :user,
            class_name: "Lesli::User",
            inverse_of: :journals
    end
end
