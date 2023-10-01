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
    class Users::RegistrationServices < ApplicationLesliServices

        # @overwrite
        # @return {Hash} Paginated list of the records
        # @param {query} Has of the formated queries/filters that will be applied to filter data
        # @description
        # @example
        def index 
            period = 'month'
            #Get filters from http request     
            group = query[:group]
            #Get period only if the request have filters
            unless group.blank?
                period = group
            end

            unless period.blank? || (period != 'day' && period != 'week' && period != 'month' && period != 'year')
                registrations = current_user.account.users.group("DATE_TRUNC('#{period}', created_at)")
                registrations.order("date_trunc_#{period}_created_at DESC").count.map do |request|
                    { 
                        :date => Date2.new(request[0]).date.to_s,
                        :count => request[1]
                    }
                end
            end
        end

    end
end
