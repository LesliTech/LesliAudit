=begin

Lesli

Copyright (c) 2025, Lesli Technologies, S. A.

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

Lesli · Ruby on Rails SaaS Development Framework.

Made with ♥ by LesliTech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end

class CreateLesliAuditUserLogs < ActiveRecord::Migration[6.0]
    def change
        create_table :lesli_audit_user_logs do |t|
            t.string :engine
            t.string :action

            # Polymorphic subject
            t.string :subject_type
            t.bigint :subject_id

            t.string :operation
            t.string :description
            t.bigint :session_id

            t.timestamps
        end

        add_reference(:lesli_audit_user_logs, :user, foreign_key: { to_table: :lesli_users }) 
        add_reference(:lesli_audit_user_logs, :account, foreign_key: { to_table: :lesli_audit_accounts })
    end
end
