module LesliAudit
    module UserAssociations
        extend ActiveSupport::Concern

        included do
            has_many :requests, class_name: "LesliAudit::UserRequest"
            has_many :journals, class_name: "LesliAudit::UserJournal"
            has_many :logs, class_name: "LesliAudit::UserLog"
        end
    end
end
