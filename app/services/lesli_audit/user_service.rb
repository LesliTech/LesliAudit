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
    class UserService < Lesli::ApplicationLesliService

        def registrations

            #Get filters from the request     
            group = query[:group]
            group = "month"

            #Get period only if the request have filters
            period = group unless group.blank?

            group_by = "DATE_TRUNC('month', created_at)" if group == 'month'
            group_by = "DATE_TRUNC('week', created_at)" if group == 'week'
            group_by = "DATE_TRUNC('day', created_at)" if group == 'day'

            # compatibility for SQLite
            if ActiveRecord::Base.connection.adapter_name == "SQLite"
                group_by = "strftime('%Y-%m', created_at)"
            end

            registrations = []

            if ["day", "week", "month", "year"].include?(period)

                registrations = current_user.account.users
                .group(group_by)
                .count.map do |request|
                    {
                        :date => request[0],
                        :count => request[1]
                    }
                end
            end

            registrations
        end
    end
end
