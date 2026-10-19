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

class CreateLesliAuditUserRequests < ActiveRecord::Migration[8.1]
    def change
        create_table :lesli_audit_user_requests do |t|
            t.string :request_controller, null: false
            t.string :request_action, null: false
            t.bigint :request_count, null: false, default: 0
            t.date :date, null: false
            t.string :session_id
            t.timestamps null: false
        end
        add_reference(:lesli_audit_user_requests, :user, null: false, foreign_key: { to_table: :lesli_users, on_delete: :cascade })
        add_reference(:lesli_audit_user_requests, :account, null: false, foreign_key: { to_table: :lesli_audit_accounts, on_delete: :cascade })
        add_check_constraint(:lesli_audit_user_requests, "request_count >= 0", name: "lesli_audit_user_requests_request_count_nonnegative")
        add_index(:lesli_audit_user_requests, %i[account_id user_id session_id date request_controller request_action], unique: true, name: "lesli_audit_user_requests_index")
        add_index(:lesli_audit_user_requests, %i[account_id date], name: "index_lesli_audit_user_requests_on_account_and_date")
        add_index(:lesli_audit_user_requests, :date, name: "index_lesli_audit_user_requests_on_date")
    end
end
