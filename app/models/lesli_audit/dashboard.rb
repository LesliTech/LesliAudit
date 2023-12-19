module LesliAudit
    #class Dashboard < Lesli::ApplicationLesliRecord
    class Dashboard < Lesli::Shared::Dashboard
        self.table_name = "lesli_audit_dashboards"
        belongs_to :account

        has_many :components, inverse_of: :dashboard, autosave: true, dependent: :destroy
        accepts_nested_attributes_for :components, allow_destroy: true

        def self.initialize_data(account)
            self.create!(
                account: account,
                name: "Audit Default Dashboard",
                default: true,
                main: false,
                components_attributes: [{
                    name: "Total users",
                    component_id: "users",
                    layout: 4,
                    query_configuration: {},
                    custom_configuration: {}
                }, {
                    name: "Active roles",
                    component_id: "active-roles",
                    layout: 4,
                    query_configuration: {},
                    custom_configuration: {}
                }]
            )
        end
    end
end
