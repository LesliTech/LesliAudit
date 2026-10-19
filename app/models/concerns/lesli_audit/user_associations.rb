module LesliAudit
    module UserAssociations
        extend ActiveSupport::Concern

        included do
            has_many :requests,
                class_name: "LesliAudit::UserRequest",
                foreign_key: :user_id,
                inverse_of: :user

            has_many :journals,
                class_name: "LesliAudit::UserJournal",
                foreign_key: :user_id,
                inverse_of: :user

            has_many :logs,
                class_name: "LesliAudit::UserLog",
                foreign_key: :user_id,
                inverse_of: :user

            has_many :account_logs,
                class_name: "LesliAudit::AccountLog",
                foreign_key: :user_id,
                inverse_of: :user
        end
    end
end
