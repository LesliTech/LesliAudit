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

Lesli · Ruby on Rails SaaS development platform.

Made with ♥ by https://www.lesli.tech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end

module LesliAudit
    class Account::ActivityServices < Lesli::ApplicationLesliService

        def index
            search_string = nil # query[:search].downcase.gsub(" ","%") unless query[:search].blank?

            activities = current_user.account.activities

            activities = activities.select(
                :id,
                :title,
                :description,
                :system_process,
                :system_module,
                "payload ->'to'->>0 as send_to",
                Date2.new.date_time.db_timestamps()
            )

            # search if search params was sent
            unless search_string.blank?
                activities = activities.where(["
                    system_module like :search_string 
                    or system_process like :search_string 
                    or description like :search_string 
                    or title like :search_string 
                    or payload->'to'->>0 like :search_string",
                ].join(" or "), { 
                    search_string: "%#{search_string}%"
                }) 
            end

            activities.page(query[:pagination][:page])
            .per(query[:pagination][:perPage])
            .order(created_at: :desc)
        end
    end
end
