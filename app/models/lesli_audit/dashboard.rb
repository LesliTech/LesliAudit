module LesliAudit
    #class Dashboard < Lesli::ApplicationLesliRecord
    class Dashboard < Lesli::Shared::Dashboard
        self.table_name = "lesli_audit_dashboards"
        belongs_to :account

        has_many :components, inverse_of: :dashboard, autosave: true, dependent: :destroy
        accepts_nested_attributes_for :components, allow_destroy: true

        def self.initialize_account(account)
            # self.create!(
            #     account: account,
            #     name: "Audit Default Dashboard",
            #     default: true,
            #     main: false,
            #     components_attributes: [{
            #         name: "Total users",
            #         component_id: "audit-users",
            #         layout: 3,
            #         query_configuration: {},
            #         custom_configuration: {}
            #     }, {
            #         name: "Roles",
            #         component_id: "audit-roles",
            #         layout: 3,
            #         query_configuration: {},
            #         custom_configuration: {}
            #     }]
            # )
        end
    end
end
