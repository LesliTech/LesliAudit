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

        def users
            users = current_user.account.users

            now = Time.current
            last_30_days = 30.days.ago

            stats = users.pick(
                # total users 
                Arel.sql("COUNT(*)"),

                # total active users
                Arel.sql("SUM(CASE WHEN active = 1 AND deleted_at IS NULL THEN 1 ELSE 0 END)"),

                # total inactive users 
                Arel.sql("SUM(CASE WHEN active = 0 AND deleted_at IS NULL THEN 1 ELSE 0 END)"),

                # total locked users 
                Arel.sql(
                    "SUM(CASE WHEN (
                        locked_at IS NOT NULL
                        OR locked_until > #{ActiveRecord::Base.connection.quote(Time.current)}
                    ) AND deleted_at IS NULL THEN 1 ELSE 0 END)"
                ),

                # not confirmed users
                Arel.sql("SUM(CASE WHEN confirmed_at IS NULL AND deleted_at IS NULL THEN 1 ELSE 0 END)"),

                # users that never signed in 
                Arel.sql("SUM(CASE WHEN last_sign_in_at IS NULL AND deleted_at IS NULL THEN 1 ELSE 0 END)"),

                # total active users for the last 30 days 
                Arel.sql("SUM(CASE WHEN last_sign_in_at >= #{ActiveRecord::Base.connection.quote(last_30_days)} AND deleted_at IS NULL THEN 1 ELSE 0 END)"),

                # total new users for the last 30 days 
                Arel.sql("SUM(CASE WHEN created_at >= #{ActiveRecord::Base.connection.quote(last_30_days)} AND deleted_at IS NULL THEN 1 ELSE 0 END)"),

                # users with failed logins
                Arel.sql("SUM(CASE WHEN failed_attempts > 0 AND deleted_at IS NULL THEN 1 ELSE 0 END)"),

                # deleted users 
                Arel.sql("SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END)")
            )

            summary = { total_users: stats[0].to_i, total_active_users: stats[1].to_i, total_inactive_users: stats[2].to_i, total_locked_users: stats[3].to_i, total_unconfirmed_users: stats[4].to_i, total_users_never_signed_in: stats[5].to_i, total_users_active_last_30_days: stats[6].to_i, total_new_users_last_30_days: stats[7].to_i, total_users_with_failed_attempts: stats[8].to_i, total_deleted_users: stats[9].to_i }

            {
                overview: [
                    {
                        key: :total_users,
                        label: "Total users",
                        value: summary[:total_users],
                        percentage: 100
                    },
                    {
                        key: :total_active_users,
                        label: "Active users",
                        value: summary[:total_active_users],
                        percentage: percentage(summary[:total_active_users], summary[:total_users])
                    },
                    {
                        key: :total_inactive_users,
                        label: "Inactive users",
                        value: summary[:total_inactive_users],
                        percentage: percentage(summary[:total_inactive_users], summary[:total_users])
                    },
                    {
                        key: :total_locked_users,
                        label: "Locked users",
                        value: summary[:total_locked_users],
                        percentage: percentage(summary[:total_locked_users], summary[:total_users])
                    }
                ],

                distribution: [
                    {
                        label: "Active",
                        value: summary[:total_active_users],
                        percentage: percentage(summary[:total_active_users], summary[:total_users]),
                        color: "#1F6F8B"
                    },
                    {
                        label: "Inactive",
                        value: summary[:total_inactive_users],
                        percentage: percentage(summary[:total_inactive_users], summary[:total_users]),
                        color: "#5D7C4D"
                    },
                    {
                        label: "Locked",
                        value: summary[:total_locked_users],
                        percentage: percentage(summary[:total_locked_users], summary[:total_users]),
                        color: "#B23A3A"
                    },
                    {
                        label: "Deleted",
                        value: summary[:total_deleted_users],
                        percentage: percentage(summary[:total_deleted_users], summary[:total_users]),
                        color: "#5F6C7D"
                    },
                    {
                        label: "Unconfirmed",
                        value: summary[:total_unconfirmed_users],
                        percentage: percentage(summary[:total_unconfirmed_users], summary[:total_users]),
                        color: "#4B5FA8"
                    }
                ],

                activity: [
                    {
                        key: :total_users_active_last_30_days,
                        label: "Active last 30 days",
                        value: summary[:total_users_active_last_30_days],
                        percentage: percentage(summary[:total_users_active_last_30_days], summary[:total_users])
                    },
                    {
                        key: :total_new_users_last_30_days,
                        label: "New users last 30 days",
                        value: summary[:total_new_users_last_30_days],
                        percentage: percentage(summary[:total_new_users_last_30_days], summary[:total_users])
                    },
                    {
                        key: :total_users_never_signed_in,
                        label: "Never signed in",
                        value: summary[:total_users_never_signed_in],
                        percentage: percentage(summary[:total_users_never_signed_in], summary[:total_users])
                    },
                    {
                        key: :total_users_with_failed_attempts,
                        label: "With failed attempts",
                        value: summary[:total_users_with_failed_attempts],
                        percentage: percentage(summary[:total_users_with_failed_attempts], summary[:total_users])
                    },
                    {
                        key: :total_unconfirmed_users,
                        label: "Unconfirmed users",
                        value: summary[:total_unconfirmed_users],
                        percentage: percentage(summary[:total_unconfirmed_users], summary[:total_users])
                    }
                ]
            }
        end

        def working_hours

            group = 'day' 

            group_by = "DATE_TRUNC('month', lesli_audit_user_requests.date)" if group == 'month'
            group_by = "DATE_TRUNC('week', lesli_audit_user_requests.date)" if group == 'week'
            group_by = "DATE_TRUNC('day', lesli_audit_user_requests.date)" if group == 'day'

            # compatibility for SQLite
            if ActiveRecord::Base.connection.adapter_name == "SQLite"
                group_by = "strftime('%Y-%m-%d', lesli_audit_user_requests.date)"
            end

            user_requests = current_user.account.users.joins(:requests)

            user_requests = user_requests.select(
                :id,
                "lesli_users.id as user_id",
                "lesli_users.email as user_email",
                "#{group_by} date",
                "min(lesli_audit_user_requests.created_at) as first_activity", 
                "max(lesli_audit_user_requests.updated_at) as last_activity",
                "count(lesli_audit_user_requests.id) resources", 
                "sum(lesli_audit_user_requests.request_count) requests"
            )
           
            user_requests = user_requests.group(:user_id, group_by)

            user_requests.map do |request|
                request[:first_activity] = Date2.new(request[:first_activity]).time
                request[:last_activity] = Date2.new(request[:last_activity]).time
                request
            end
            
            user_requests.reverse
        end

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
                        :xaxiskey => request[0],
                        :yaxiskey => request[1]
                    }
                end
            end

            registrations
        end

        private 

        def percentage(value, total)
            return 0 if total.to_i.zero?
            ((value.to_f / total) * 100).round
        end
    end
end
