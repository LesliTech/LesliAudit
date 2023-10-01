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
    class RequestServices < ApplicationLesliServices

        # @overwrite
        # @return {Hash} Paginated list of the records
        # @param {query} Has of the formated queries/filters that will be applied to filter data
        # @description
        # @example
        def index 
            search_string = nil # query[:search].downcase.gsub(" ","%") unless query[:search].blank?
            order_string = "user_requests.created_at" 
            
            user_requests = current_user.account.users.joins(:requests)
            #user_requests = user_requests.where("users.email = ?", query[:filters][:user]) unless query[:filters][:user].blank?

            if !search_string.blank?
                # user_requests = user_requests.where([
                #     "lower(users.email) like :search_string",
                #     "lower(request_controller) like :search_string",
                #     "lower(request_action) like :search_string"
                # ].join(" or "), { 
                #     search_string: "%#{search_string}%"
                # }) 
            end

            user_requests.select(
                :id,
                "users.id as user_id",
                "users.email",
                :request_controller,
                :request_action,
                :request_method,
                :user_session_id,
                Date2.new.date_time.db_timestamps("user_requests")
            ).page(query[:pagination][:page])
            .per(query[:pagination][:perPage])
        end
    end
end
