class CreateLesliAuditVisitorRollups < ActiveRecord::Migration[8.1]
    def change
        create_table :lesli_audit_visitor_rollups do |t|
            t.string :provider, null: false
            t.string :provider_key, null: false
            t.string :resource_type, null: false
            t.bigint :resource_id, null: false
            t.date :date, null: false
            t.bigint :page_views, null: false, default: 0
            t.bigint :visits, null: false, default: 0
            t.datetime :synced_at, null: false
            t.timestamps null: false
        end

        add_reference(
            :lesli_audit_visitor_rollups,
            :account,
            null: false,
            foreign_key: { to_table: :lesli_audit_accounts, on_delete: :cascade }
        )

        add_check_constraint(
            :lesli_audit_visitor_rollups,
            "resource_id > 0",
            name: "lesli_audit_visitor_rollups_resource_id_positive"
        )
        add_check_constraint(
            :lesli_audit_visitor_rollups,
            "page_views >= 0",
            name: "lesli_audit_visitor_rollups_page_views_nonnegative"
        )
        add_check_constraint(
            :lesli_audit_visitor_rollups,
            "visits >= 0",
            name: "lesli_audit_visitor_rollups_visits_nonnegative"
        )
        add_index(
            :lesli_audit_visitor_rollups,
            %i[account_id provider provider_key date],
            unique: true,
            name: "index_lesli_audit_visitor_rollups_on_provider_key_and_date"
        )
        add_index(
            :lesli_audit_visitor_rollups,
            %i[account_id resource_type resource_id date],
            name: "index_lesli_audit_visitor_rollups_on_resource_and_date"
        )
        add_index(
            :lesli_audit_visitor_rollups,
            :date,
            name: "index_lesli_audit_visitor_rollups_on_date"
        )
    end
end
