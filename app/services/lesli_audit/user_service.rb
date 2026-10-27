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
        REGISTRATION_MONTHS = 12
        ACTIVITY_DAYS = 30
        ACTIVITY_LIMIT = 20

        def dashboard
            {
                summary: summary,
                attention: attention,
                registrations: registrations,
                working_hours: working_hours
            }
        end

        private

        def summary
            {
                registered: all_users.count,
                enabled: current_users.where(active: true).count,
                active_last_30_days: current_users.where(last_sign_in_at: ACTIVITY_DAYS.days.ago..).count,
                deactivated: current_users.where(active: false).count,
                deleted: all_users.where.not(deleted_at: nil).count
            }
        end

        def attention
            {
                unconfirmed: current_users.where(confirmed_at: nil).count,
                never_signed_in: current_users.where(last_sign_in_at: nil).count,
                failed_sign_ins: current_users.where(failed_attempts: 1..).count,
                locked: locked_users.count
            }
        end

        def locked_users
            locked_at = current_users.where.not(locked_at: nil)
            locked_until = current_users.where(locked_until: Time.current..)

            locked_at.or(locked_until)
        end

        def registrations
            counts = all_users
                .where(created_at: registration_start.beginning_of_day..)
                .group(Arel.sql(registration_month_group))
                .count
                .to_h do |month, count|
                    [ month.to_date.beginning_of_month, count ]
                end

            registration_months.map do |month|
                {
                    "xaxiskey" => month.iso8601,
                    "yaxiskey" => counts.fetch(month, 0)
                }
            end
        end

        def registration_months
            REGISTRATION_MONTHS.times.map do |offset|
                registration_start >> offset
            end
        end

        def registration_start
            (Date.current << (REGISTRATION_MONTHS - 1)).beginning_of_month
        end

        # PostgreSQL and SQLite expose different date-grouping functions. Both
        # expressions return a month that is normalized to a Date immediately.
        def registration_month_group
            return "strftime('%Y-%m-01', lesli_users.created_at)" if sqlite?

            "DATE_TRUNC('month', lesli_users.created_at)"
        end

        def working_hours
            # Journals are reduced to a daily boundary instead of exposed as a
            # request list. Requests keeps ownership of endpoint-level detail.
            journals = audit_account.user_journals
                .retained
                .where(date: activity_start..Date.current)

            account_users
                .joins(:journals)
                .merge(journals)
                .select(
                    "lesli_users.id AS user_id",
                    "lesli_users.email AS user_email",
                    "#{activity_day_group} AS activity_date",
                    "MIN(lesli_audit_user_journals.created_at) AS first_activity",
                    "MAX(lesli_audit_user_journals.created_at) AS last_activity"
                )
                .group("lesli_users.id", "lesli_users.email", Arel.sql(activity_day_group))
                .order(Arel.sql("#{activity_day_group} DESC"), "lesli_users.email ASC")
                .limit(ACTIVITY_LIMIT)
                .map { |activity| normalize_activity(activity) }
        end

        def activity_start
            (ACTIVITY_DAYS - 1).days.ago.to_date
        end

        def activity_day_group
            return "strftime('%Y-%m-%d', lesli_audit_user_journals.date)" if sqlite?

            "DATE_TRUNC('day', lesli_audit_user_journals.date)"
        end

        def normalize_activity(activity)
            {
                user_id: activity[:user_id],
                user_email: activity[:user_email],
                date: activity[:activity_date].to_date,
                first_activity: normalize_time(activity[:first_activity]),
                last_activity: normalize_time(activity[:last_activity])
            }
        end

        def normalize_time(value)
            time = if value.respond_to?(:in_time_zone)
                value.in_time_zone
            else
                Time.zone.parse(value.to_s)
            end

            time.strftime("%H:%M")
        end

        def account_users
            current_user.account.users
        end

        def all_users
            @all_users ||= account_users.with_deleted
        end

        def current_users
            @current_users ||= all_users.where(deleted_at: nil)
        end

        def audit_account
            @audit_account ||= LesliAudit::Account.find_by!(account_id: current_user.account_id)
        end

        def sqlite?
            ActiveRecord::Base.connection.adapter_name == "SQLite"
        end
    end
end
