# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 501130310) do
  create_table "lesli_accounts", force: :cascade do |t|
    t.string "status", null: false
    t.string "name"
    t.string "email", null: false
    t.string "region", default: "america"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["deleted_at"], name: "index_lesli_accounts_on_deleted_at"
    t.index ["email"], name: "index_lesli_accounts_on_email", unique: true
  end

  create_table "lesli_audit_account_devices", force: :cascade do |t|
    t.string "agent_platform", null: false
    t.string "agent_browser", null: false
    t.string "agent_device", null: false
    t.bigint "agent_count", default: 0, null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id", null: false
    t.index ["account_id", "date", "agent_platform", "agent_browser", "agent_device"], name: "lesli_audit_devices_index", unique: true
    t.index ["date"], name: "index_lesli_audit_account_devices_on_date"
    t.check_constraint "agent_count >= 0", name: "lesli_audit_account_devices_agent_count_nonnegative"
  end

  create_table "lesli_audit_account_logs", force: :cascade do |t|
    t.string "engine"
    t.string "source"
    t.string "action"
    t.string "subject_type"
    t.bigint "subject_id"
    t.string "operation", null: false
    t.text "description"
    t.string "session_id"
    t.string "actor_uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "account_id", null: false
    t.index ["account_id", "created_at"], name: "index_lesli_audit_account_logs_on_account_and_created_at"
    t.index ["created_at"], name: "index_lesli_audit_account_logs_on_created_at"
  end

  create_table "lesli_audit_account_requests", force: :cascade do |t|
    t.string "request_controller", null: false
    t.string "request_action", null: false
    t.bigint "request_count", default: 0, null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id", null: false
    t.index ["account_id", "date", "request_controller", "request_action"], name: "lesli_audit_account_requests_index", unique: true
    t.index ["date"], name: "index_lesli_audit_account_requests_on_date"
    t.check_constraint "request_count >= 0", name: "lesli_audit_account_requests_request_count_nonnegative"
  end

  create_table "lesli_audit_accounts", force: :cascade do |t|
    t.string "name"
    t.integer "status", default: 0, null: false
    t.datetime "enabled_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id", null: false
    t.index ["account_id"], name: "index_lesli_audit_accounts_on_account_id", unique: true
    t.index ["deleted_at"], name: "index_lesli_audit_accounts_on_deleted_at"
  end

  create_table "lesli_audit_cloudflare_traffic_syncs", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "zone_id", null: false
    t.date "period_start", null: false
    t.date "period_end", null: false
    t.string "status", default: "pending", null: false
    t.string "execution_id"
    t.integer "snapshots_count", default: 0, null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "last_synced_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "zone_id", "period_start", "period_end"], name: "index_lesli_audit_cloudflare_syncs_on_account_zone_and_period", unique: true
    t.index ["account_id"], name: "index_lesli_audit_cloudflare_traffic_syncs_on_account_id"
    t.check_constraint "period_start <= period_end", name: "lesli_audit_cloudflare_syncs_valid_period"
    t.check_constraint "snapshots_count >= 0", name: "lesli_audit_cloudflare_syncs_snapshots_count_nonnegative"
    t.check_constraint "status IN ('pending', 'running', 'succeeded', 'failed')", name: "lesli_audit_cloudflare_syncs_valid_status"
  end

  create_table "lesli_audit_traffic_breakdowns", force: :cascade do |t|
    t.string "dimension", null: false
    t.string "value", null: false
    t.bigint "page_views", default: 0, null: false
    t.bigint "visits", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id", null: false
    t.integer "traffic_rollup_id", null: false
    t.index ["account_id", "traffic_rollup_id", "dimension", "value"], name: "index_lesli_audit_traffic_breakdowns_on_dimension", unique: true
    t.index ["traffic_rollup_id"], name: "index_lesli_audit_traffic_breakdowns_on_traffic_rollup_id"
    t.check_constraint "page_views >= 0", name: "lesli_audit_traffic_breakdowns_page_views_nonnegative"
    t.check_constraint "visits >= 0", name: "lesli_audit_traffic_breakdowns_visits_nonnegative"
  end

  create_table "lesli_audit_traffic_rollups", force: :cascade do |t|
    t.string "provider", null: false
    t.string "hostname", null: false
    t.string "path", null: false
    t.string "resource_type", null: false
    t.bigint "resource_id", null: false
    t.date "date", null: false
    t.bigint "page_views", default: 0, null: false
    t.bigint "visits", default: 0, null: false
    t.datetime "snapshot_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id", null: false
    t.index ["account_id", "provider", "hostname", "path", "date"], name: "index_lesli_audit_traffic_rollups_on_provider_path_and_date", unique: true
    t.index ["account_id", "resource_type", "resource_id", "date"], name: "index_lesli_audit_traffic_rollups_on_resource_and_date"
    t.index ["date"], name: "index_lesli_audit_traffic_rollups_on_date"
    t.check_constraint "page_views >= 0", name: "lesli_audit_traffic_rollups_page_views_nonnegative"
    t.check_constraint "resource_id > 0", name: "lesli_audit_traffic_rollups_resource_id_positive"
    t.check_constraint "visits >= 0", name: "lesli_audit_traffic_rollups_visits_nonnegative"
  end

  create_table "lesli_audit_user_journals", force: :cascade do |t|
    t.string "event_uid", null: false
    t.string "request_controller"
    t.string "request_action"
    t.date "date", null: false
    t.string "session_id"
    t.string "agent_platform"
    t.string "agent_browser"
    t.string "agent_device"
    t.boolean "retain", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "account_id", null: false
    t.index ["account_id", "date"], name: "index_lesli_audit_user_journals_on_account_and_date"
    t.index ["account_id", "event_uid"], name: "lesli_audit_user_journals_event_index", unique: true
    t.index ["date"], name: "index_lesli_audit_user_journals_on_date"
  end

  create_table "lesli_audit_user_logs", force: :cascade do |t|
    t.string "engine"
    t.string "source"
    t.string "action"
    t.string "operation", null: false
    t.text "description"
    t.string "session_id"
    t.string "actor_uid"
    t.string "subject_type"
    t.bigint "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "account_id", null: false
    t.index ["account_id", "created_at"], name: "index_lesli_audit_user_logs_on_account_and_created_at"
    t.index ["created_at"], name: "index_lesli_audit_user_logs_on_created_at"
    t.index ["user_id", "created_at"], name: "index_lesli_audit_user_logs_on_user_and_created_at"
  end

  create_table "lesli_audit_user_requests", force: :cascade do |t|
    t.string "request_controller", null: false
    t.string "request_action", null: false
    t.bigint "request_count", default: 0, null: false
    t.date "date", null: false
    t.string "session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "account_id", null: false
    t.index ["account_id", "date"], name: "index_lesli_audit_user_requests_on_account_and_date"
    t.index ["account_id", "user_id", "session_id", "date", "request_controller", "request_action"], name: "lesli_audit_user_requests_index", unique: true
    t.index ["date"], name: "index_lesli_audit_user_requests_on_date"
    t.check_constraint "request_count >= 0", name: "lesli_audit_user_requests_request_count_nonnegative"
  end

  create_table "lesli_users", force: :cascade do |t|
    t.string "uid", null: false
    t.boolean "active", default: true, null: false
    t.string "first_name"
    t.string "last_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "locked_until"
    t.string "unlock_token"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "password_expiration_at"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.datetime "confirmed_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.index ["account_id"], name: "index_lesli_users_on_account_id"
    t.index ["deleted_at"], name: "index_lesli_users_on_deleted_at"
    t.index ["email"], name: "index_lesli_users_on_email", unique: true
    t.index ["uid"], name: "index_lesli_users_on_uid", unique: true
  end

  add_foreign_key "lesli_audit_account_devices", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_account_logs", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_account_logs", "lesli_users", column: "user_id", on_delete: :nullify
  add_foreign_key "lesli_audit_account_requests", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_accounts", "lesli_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_cloudflare_traffic_syncs", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_traffic_breakdowns", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_traffic_breakdowns", "lesli_audit_traffic_rollups", column: "traffic_rollup_id", on_delete: :cascade
  add_foreign_key "lesli_audit_traffic_rollups", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_user_journals", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_user_journals", "lesli_users", column: "user_id", on_delete: :nullify
  add_foreign_key "lesli_audit_user_logs", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_user_logs", "lesli_users", column: "user_id", on_delete: :nullify
  add_foreign_key "lesli_audit_user_requests", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
  add_foreign_key "lesli_audit_user_requests", "lesli_users", column: "user_id", on_delete: :cascade
  add_foreign_key "lesli_users", "lesli_accounts", column: "account_id"
end
