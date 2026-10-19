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

class CreateLesliAuditAccountDevices < ActiveRecord::Migration[8.1]
    def change
        create_table :lesli_audit_account_devices do |t|
            t.string :agent_platform, null: false
            t.string :agent_browser, null: false
            t.string :agent_device, null: false
            t.bigint :agent_count, null: false, default: 0
            t.date :date, null: false
            t.timestamps null: false
        end

        add_reference(:lesli_audit_account_devices, :account, null: false, foreign_key: { to_table: :lesli_audit_accounts })
        add_check_constraint(:lesli_audit_account_devices, "agent_count >= 0", name: "lesli_audit_account_devices_agent_count_nonnegative")
        add_index(:lesli_audit_account_devices, %i[account_id date agent_platform agent_browser agent_device], unique: true, name: "lesli_audit_devices_index")
    end
end
