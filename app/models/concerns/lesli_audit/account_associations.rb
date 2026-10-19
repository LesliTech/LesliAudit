module LesliAudit
    module AccountAssociations
        extend ActiveSupport::Concern

        included do
            has_one :audit,
                class_name: "LesliAudit::Account",
                foreign_key: :account_id,
                inverse_of: :account
        end
    end
end
