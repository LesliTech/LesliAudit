module LesliAudit
    class Log < ApplicationRecord
        belongs_to :account, class_name: 'Lesli::Account'
        belongs_to :user, class_name: 'Lesli::User'
    end
end
