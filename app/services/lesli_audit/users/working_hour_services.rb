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

module CloudAudit
    class Users::WorkingHourServices < ApplicationLesliServices

        # @overwrite
        # @return {Hash} Paginated list of the records
        # @param {query} Has of the formated queries/filters that will be applied to filter data
        # @description
        # @example
        def index 
            
            #Get string for search query
            search_string = query[:search].downcase.gsub(" ","%") unless query[:search].blank?

            #Order by column in table of users
            order_string = "date"
            unless query.dig(:order, :by).blank?
                order_string = query.dig(:order, :by)
            end

            user_requests = current_user.account.users.joins(:requests).joins(:roles)

            user_requests = user_requests.select(
                :id,
                "users.id as userid",
                "users.email",
                "DATE_TRUNC('day', user_requests.created_at) as date",
                "min(user_requests.created_at) as first_activity", 
                "max(user_requests.created_at) as last_activity",
                "roles.name"
            ).order(order_string.concat(" ").concat(query.dig(:order, :dir)))

                        
            user_requests = user_requests.group(:userid, "DATE_TRUNC('day', user_requests.created_at)", "roles.name")

            unless search_string.blank?
                user_requests = user_requests.where([
                    "lower(users.email) like :search_string or lower(roles.name) like :search_string",
                ].join(" or "), { 
                    search_string: "%#{search_string}%"
                }) 
            end

            user_requests
        end
    end
end
