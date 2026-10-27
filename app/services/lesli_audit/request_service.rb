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

Lesli · Ruby on Rails SaaS Development Framework.

Made with ♥ by https://www.lesli.tech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// ·
=end

module LesliAudit
    class RequestService < Lesli::ApplicationLesliService
        ACCOUNT_WIDE_ROLES = %w[owner admin].freeze
        DEFAULT_PER_PAGE = 12
        MAX_PER_PAGE = 100

        SORT_COLUMNS = {
            "user" => Lesli::User.arel_table[:email],
            "controller" => UserRequest.arel_table[:request_controller],
            "action" => UserRequest.arel_table[:request_action],
            "count" => UserRequest.arel_table[:request_count],
            "date" => UserRequest.arel_table[:date]
        }.freeze

        def index
            requests = current_user.account.audit.user_requests
                .joins(:user)
                .select(
                    "lesli_audit_user_requests.*",
                    "lesli_users.email AS user_email"
                )

            requests = requests.where(user_id: current_user.id) unless account_wide?
            requests = apply_search(requests)

            requests
                .order(sort_order, id: :desc)
                .page(page)
                .per(per_page)
        end

        private

        # LesliShield authorizes access to the controller. Built-in owner and
        # admin roles additionally receive the account-wide reporting scope.
        def account_wide?
            current_user.respond_to?(:has_roles?) &&
                current_user.has_roles?(*ACCOUNT_WIDE_ROLES)
        end

        def apply_search(requests)
            term = query[:search].to_s.strip
            return requests if term.blank?

            pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term.downcase)}%"

            requests.where(
                <<~SQL.squish,
                    LOWER(lesli_users.email) LIKE :pattern
                    OR LOWER(lesli_audit_user_requests.request_controller) LIKE :pattern
                    OR LOWER(lesli_audit_user_requests.request_action) LIKE :pattern
                SQL
                pattern: pattern
            )
        end

        def sort_column
            SORT_COLUMNS.fetch(query.dig(:order, :by).to_s, SORT_COLUMNS.fetch("date"))
        end

        def sort_order
            return sort_column.asc if query.dig(:order, :dir).to_s.casecmp?("asc")

            sort_column.desc
        end

        def page
            requested_page = query.dig(:pagination, :page).to_i
            requested_page.positive? ? requested_page : 1
        end

        def per_page
            requested_size = query.dig(:pagination, :perPage).to_i
            return DEFAULT_PER_PAGE unless requested_size.positive?

            [ requested_size, MAX_PER_PAGE ].min
        end
    end
end
