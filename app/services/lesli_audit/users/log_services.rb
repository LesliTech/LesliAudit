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
    class Users::LogServices < ApplicationLesliServices

        # @overwrite
        # @return {Hash} Paginated list of the records
        # @param {query} Has of the formated queries/filters that will be applied to filter data
        # @description
        # @example
        def index 
            search_string = query[:search].downcase.gsub(" ","%") unless query[:search].blank?

            records = current_user.account.users.joins(:logs)
            #records = records.where("users.email = ?", query[:filters][:user]) unless query[:filters][:user].blank?
            records = records.where("title like :search or description like :search", { search: "%#{search_string}%"}) unless search_string.blank?
            records = records.select(
                :id,
                "users.id as user_id",
                "users.email",
                :title,
                :description,
                Date2.new.date_time.db_timestamps("user_logs")
            )
            .page(query[:pagination][:page])
            .per(query[:pagination][:perPage])
            .order("user_logs.created_at DESC")

            records
        end
    end
end
