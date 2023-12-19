module LesliAudit
    class Dashboard::Component < ApplicationRecord

        belongs_to :dashboard, inverse_of: :components

        def self.component_ids
            ["users", "active_roles"]
        end
        # components_ids: {
        #     list_new_tickets: "list_new_tickets",
        #     list_my_tickets: "list_my_tickets",
        #     list_unassigned_tickets: "list_unassigned_tickets",
        #     chart_tickets_by_type: "chart_tickets_by_type",
        #     chart_tickets_by_category: "chart_tickets_by_category",
        #     hours_worked: "hours_worked"
        # }
    end
end
