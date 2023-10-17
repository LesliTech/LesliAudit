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
    class AnalyticService < Lesli::ApplicationLesliService

        LIMIT=5

        # @overwrite
        # @return {Hash} Paginated list of the records
        # @param {query} Has of the formated queries/filters that will be applied to filter data
        # @description
        # @example
        def visitors 

            group = 'day' 
            #group = params[:bygroup] if ['month','week','day'].include?(params[:bygroup])

            # only the users of the account
            usrs = current_user.account.users


            requests = current_user.account.audit.account_requests
            requests = requests.group("DATE_TRUNC('month', created_at)") if group == 'month'
            requests = requests.group("DATE_TRUNC('week', created_at)") if group == 'week'
            requests = requests.group("DATE_TRUNC('day', created_at)") if group == 'day'

            requests = apply_filters(requests, query)
            
            requests.limit(30).order("date DESC").select(
                "count(id) resources", 
                "sum(request_count) requests",
                "DATE_TRUNC('day', created_at) date"
            )
        end

        def users 

            current_user.account.audit.user_requests
            .joins(:user)
            .group(:email)
            .limit(LIMIT).order("requests DESC").select(
                :email,
                "count(lesli_audit_user_requests.id) resources", 
                "sum(lesli_audit_user_requests.request_count) requests"
            )
        end

        def controllers 
            requests = current_user.account.audit.account_requests
            .group("request_controller").limit(30)

            requests = apply_filters(requests, query)

            requests = requests.limit(LIMIT).order("requests DESC").select(
                :request_controller,
                "sum(request_count) requests"
            )
        end

        private 

        def apply_filters requests, params

            return requests

            # filter by search string
            unless params[:search].blank?
                requests = requests.where(
                    "lower(request_agent) like :search_string or lower(request_controller) like :search_string or lower(request_action) like :search_string", 
                    { 
                        search_string: "%#{params[:search].downcase.gsub(" ","%")}%"
                    }
                ) 
            end

            # filter by time
            unless params[:bytime].blank? && params[:bytime] != 'all'
                requests = requests.where(created_at: (Time.now.beginning_of_day)..) if params[:bytime] == 'day'
                requests = requests.where(created_at: (Time.now.beginning_of_day - 7.day)..) if params[:bytime] == 'week'
                requests = requests.where(created_at: (Time.now.beginning_of_day - 30.day)..) if params[:bytime] == 'month'
                requests = requests.where(created_at: (Time.now.beginning_of_day - 6.month)..) if params[:bytime] == 'sixmonth'
                requests = requests.where(created_at: (Time.now.beginning_of_day - 1.year)..) if params[:bytime] == 'year'
            end

            # filter by request format
            if (!params[:byformat].blank? && ['html', 'json'].include?(params[:byformat]))
                requests = requests.where(:request_action => 'show') if params[:byformat] == 'html'
                requests = requests.where(:request_format => params[:byformat])
            end

            requests

        end
    end
end
