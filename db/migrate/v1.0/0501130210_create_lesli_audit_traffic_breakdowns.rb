class CreateLesliAuditTrafficBreakdowns < ActiveRecord::Migration[8.1]
    def change
        create_table :lesli_audit_traffic_breakdowns do |t|
            t.string :dimension, null: false
            t.string :value, null: false
            t.bigint :page_views, null: false, default: 0
            t.bigint :visits, null: false, default: 0
            t.timestamps null: false
        end

        add_reference(
            :lesli_audit_traffic_breakdowns,
            :account,
            null: false,
            foreign_key: { to_table: :lesli_audit_accounts, on_delete: :cascade }
        )
        add_reference(
            :lesli_audit_traffic_breakdowns,
            :traffic_rollup,
            null: false,
            foreign_key: { to_table: :lesli_audit_traffic_rollups, on_delete: :cascade }
        )

        add_check_constraint(
            :lesli_audit_traffic_breakdowns,
            "page_views >= 0",
            name: "lesli_audit_traffic_breakdowns_page_views_nonnegative"
        )
        add_check_constraint(
            :lesli_audit_traffic_breakdowns,
            "visits >= 0",
            name: "lesli_audit_traffic_breakdowns_visits_nonnegative"
        )
        add_index(
            :lesli_audit_traffic_breakdowns,
            %i[account_id traffic_rollup_id dimension value],
            unique: true,
            name: "index_lesli_audit_traffic_breakdowns_on_dimension"
        )
    end
end
