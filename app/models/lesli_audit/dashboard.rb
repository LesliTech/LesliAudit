module LesliAudit
    #class Dashboard < Lesli::ApplicationLesliRecord
    class Dashboard < Lesli::Shared::Dashboard
        self.table_name = "lesli_audit_dashboards"
        belongs_to :account
    end
end
