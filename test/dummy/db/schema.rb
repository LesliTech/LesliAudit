ActiveRecord::Schema[8.1].define(version: 501120310) do
    create_table "lesli_accounts", force: :cascade do |t|
        t.string "status", null: false
        t.string "name"
        t.string "email", null: false
        t.string "region", default: "america"
        t.datetime "deleted_at"
        t.timestamps null: false
        t.integer "user_id"
        t.index ["deleted_at"], name: "index_lesli_accounts_on_deleted_at"
        t.index ["email"], name: "index_lesli_accounts_on_email", unique: true
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
        t.timestamps null: false
        t.integer "account_id"
        t.index ["account_id"], name: "index_lesli_users_on_account_id"
        t.index ["deleted_at"], name: "index_lesli_users_on_deleted_at"
        t.index ["email"], name: "index_lesli_users_on_email", unique: true
        t.index ["uid"], name: "index_lesli_users_on_uid", unique: true
    end

    create_table "lesli_audit_accounts", force: :cascade do |t|
        t.string "name"
        t.integer "status", default: 0, null: false
        t.datetime "enabled_at"
        t.datetime "deleted_at"
        t.timestamps null: false
        t.integer "account_id", null: false
        t.index ["account_id"], name: "index_lesli_audit_accounts_on_account_id", unique: true
        t.index ["deleted_at"], name: "index_lesli_audit_accounts_on_deleted_at"
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
        t.timestamps null: false
        t.integer "user_id"
        t.integer "account_id", null: false
        t.index ["account_id", "created_at"], name: "index_lesli_audit_account_logs_on_account_and_created_at"
        t.index ["created_at"], name: "index_lesli_audit_account_logs_on_created_at"
    end

    create_table "lesli_audit_account_devices", force: :cascade do |t|
        t.string "agent_platform", null: false
        t.string "agent_browser", null: false
        t.string "agent_device", null: false
        t.bigint "agent_count", default: 0, null: false
        t.date "date", null: false
        t.timestamps null: false
        t.integer "account_id", null: false
        t.index ["account_id", "date", "agent_platform", "agent_browser", "agent_device"], name: "lesli_audit_devices_index", unique: true
        t.index ["date"], name: "index_lesli_audit_account_devices_on_date"
        t.check_constraint "agent_count >= 0", name: "lesli_audit_account_devices_agent_count_nonnegative"
    end

    create_table "lesli_audit_account_requests", force: :cascade do |t|
        t.string "request_controller", null: false
        t.string "request_action", null: false
        t.bigint "request_count", default: 0, null: false
        t.date "date", null: false
        t.timestamps null: false
        t.integer "account_id", null: false
        t.index ["account_id", "date", "request_controller", "request_action"], name: "lesli_audit_account_requests_index", unique: true
        t.index ["date"], name: "index_lesli_audit_account_requests_on_date"
        t.check_constraint "request_count >= 0", name: "lesli_audit_account_requests_request_count_nonnegative"
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
        t.timestamps null: false
        t.integer "user_id"
        t.integer "account_id", null: false
        t.index ["account_id", "created_at"], name: "index_lesli_audit_user_logs_on_account_and_created_at"
        t.index ["user_id", "created_at"], name: "index_lesli_audit_user_logs_on_user_and_created_at"
        t.index ["created_at"], name: "index_lesli_audit_user_logs_on_created_at"
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
        t.boolean "analytics_enabled", default: true, null: false
        t.boolean "retain", default: true, null: false
        t.datetime "processed_at"
        t.timestamps null: false
        t.integer "user_id"
        t.integer "account_id", null: false
        t.index ["account_id", "date"], name: "index_lesli_audit_user_journals_on_account_and_date"
        t.index ["account_id", "event_uid"], name: "lesli_audit_user_journals_event_index", unique: true
        t.index ["date"], name: "index_lesli_audit_user_journals_on_date"
        t.index ["processed_at"], name: "index_lesli_audit_user_journals_on_processed_at"
    end

    create_table "lesli_audit_user_requests", force: :cascade do |t|
        t.string "request_controller", null: false
        t.string "request_action", null: false
        t.bigint "request_count", default: 0, null: false
        t.date "date", null: false
        t.string "session_id"
        t.timestamps null: false
        t.integer "user_id", null: false
        t.integer "account_id", null: false
        t.index ["account_id", "user_id", "session_id", "date", "request_controller", "request_action"], name: "lesli_audit_user_requests_index", unique: true
        t.index ["account_id", "date"], name: "index_lesli_audit_user_requests_on_account_and_date"
        t.index ["date"], name: "index_lesli_audit_user_requests_on_date"
        t.check_constraint "request_count >= 0", name: "lesli_audit_user_requests_request_count_nonnegative"
    end

    add_foreign_key "lesli_users", "lesli_accounts", column: "account_id"
    add_foreign_key "lesli_audit_accounts", "lesli_accounts", column: "account_id", on_delete: :cascade
    add_foreign_key "lesli_audit_account_logs", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
    add_foreign_key "lesli_audit_account_logs", "lesli_users", column: "user_id", on_delete: :nullify
    add_foreign_key "lesli_audit_account_devices", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
    add_foreign_key "lesli_audit_account_requests", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
    add_foreign_key "lesli_audit_user_logs", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
    add_foreign_key "lesli_audit_user_logs", "lesli_users", column: "user_id", on_delete: :nullify
    add_foreign_key "lesli_audit_user_journals", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
    add_foreign_key "lesli_audit_user_journals", "lesli_users", column: "user_id", on_delete: :nullify
    add_foreign_key "lesli_audit_user_requests", "lesli_audit_accounts", column: "account_id", on_delete: :cascade
    add_foreign_key "lesli_audit_user_requests", "lesli_users", column: "user_id", on_delete: :cascade
end

