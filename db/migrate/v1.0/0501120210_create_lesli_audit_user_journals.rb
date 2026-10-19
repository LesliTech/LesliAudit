=begin

Lesli

Copyright (c) 2023, Lesli Technologies, S. A.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/.

Lesli · Ruby on Rails Development Platform.

Made with ♥ by https://www.lesli.tech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// ·
=end

class CreateLesliAuditUserJournals < ActiveRecord::Migration[8.1]
    def change
        create_table :lesli_audit_user_journals do |t|
            t.string :event_uid, null: false
            t.string :request_controller
            t.string :request_action
            t.date :date, null: false
            t.string :session_id
            t.string :agent_platform
            t.string :agent_browser
            t.string :agent_device
            t.boolean :analytics_enabled, null: false, default: true
            t.boolean :retain, null: false, default: true
            t.datetime :processed_at
            t.timestamps null: false
        end
        add_reference(:lesli_audit_user_journals, :user, null: true, foreign_key: { to_table: :lesli_users, on_delete: :nullify })
        add_reference(:lesli_audit_user_journals, :account, null: false, foreign_key: { to_table: :lesli_audit_accounts, on_delete: :cascade })
        add_index(:lesli_audit_user_journals, %i[account_id date], name: "index_lesli_audit_user_journals_on_account_and_date")
        add_index(:lesli_audit_user_journals, %i[account_id event_uid], unique: true, name: "lesli_audit_user_journals_event_index")
        add_index(:lesli_audit_user_journals, :date, name: "index_lesli_audit_user_journals_on_date")
        add_index(:lesli_audit_user_journals, :processed_at, name: "index_lesli_audit_user_journals_on_processed_at")
    end
end
