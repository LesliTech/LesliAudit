module LesliAudit
    class AccountDevice < ApplicationRecord
        belongs_to :account, class_name: 'Lesli::Account'
    end
end
