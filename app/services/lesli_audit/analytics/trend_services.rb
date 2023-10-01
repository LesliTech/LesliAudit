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
    class Analytics::TrendServices < ApplicationLesliServices

        def index

            #Default period
            period = 'day'

            #Get filters from http request
            filters = nil #params[:f]

            #Get start and final date only if the request have filters
            unless filters.blank?
                finalDate = filters[:finalDate]
                startDate = filters[:startDate]
                period = filters[:groupBy]
            end

            #Default search if range date is not provided
            user_requests = ::User::Request.select('created_at').where(created_at: (Time.now.beginning_of_day - 3.month)..)

            # Verify if there are startDate and finalDate
            unless startDate.blank? || finalDate.blank?
                user_requests = ::User::Request.where(created_at: (startDate..finalDate))
            end

            unless period.blank? || (period != 'day' && period != 'hour')
                #Group by day/time depending on the period param
                if period == 'day'
                    user_requests = user_requests.group("DATE_TRUNC('#{period}', created_at)")
                    user_requests.count.map do |request|
                        { 
                            :day => request[0].strftime('%A').to_s,
                            :count => request[1]
                        }
                    end
                    

                elsif period == 'hour'
                    user_requests = user_requests.group("DATE_PART('#{period}', created_at)").order('date_part_hour_created_at')
                    user_requests.count.map do |request|
                        { 
                        :hour => request[0],
                        :count => request[1]
                        }
                    end
                end 
            end
        end

    end
end
