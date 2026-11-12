class CreateLesliAuditCloudflareTrafficSyncs < ActiveRecord::Migration[8.1]
  def change
    create_table :lesli_audit_cloudflare_traffic_syncs do |t|
      t.references :account,
        null: false,
        foreign_key: { to_table: :lesli_audit_accounts, on_delete: :cascade }
      t.string :zone_id, null: false
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :status, null: false, default: "pending"
      t.string :execution_id
      t.integer :snapshots_count, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :last_synced_at
      t.text :error_message
      t.timestamps null: false
    end

    add_index(
      :lesli_audit_cloudflare_traffic_syncs,
      %i[account_id zone_id period_start period_end],
      unique: true,
      name: "index_lesli_audit_cloudflare_syncs_on_account_zone_and_period"
    )
    add_check_constraint(
      :lesli_audit_cloudflare_traffic_syncs,
      "period_start <= period_end",
      name: "lesli_audit_cloudflare_syncs_valid_period"
    )
    add_check_constraint(
      :lesli_audit_cloudflare_traffic_syncs,
      "snapshots_count >= 0",
      name: "lesli_audit_cloudflare_syncs_snapshots_count_nonnegative"
    )
    add_check_constraint(
      :lesli_audit_cloudflare_traffic_syncs,
      "status IN ('pending', 'running', 'succeeded', 'failed')",
      name: "lesli_audit_cloudflare_syncs_valid_status"
    )
  end
end
