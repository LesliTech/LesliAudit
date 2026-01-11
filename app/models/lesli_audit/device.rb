module LesliAudit
    class Device < ApplicationRecord
        belongs_to :account, class_name: 'Lesli::Account'
    end
end
