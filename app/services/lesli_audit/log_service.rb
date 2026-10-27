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
    class LogService < Lesli::ApplicationLesliService
        LOG_KINDS = %w[user account].freeze
        DEFAULT_KIND = "user"
        DEFAULT_PER_PAGE = 12
        MAX_PER_PAGE = 100

        SEARCH_FIELDS = %i[
            operation
            description
            source
            action
            actor_uid
            subject_type
        ].freeze

        def index
            logs = apply_search(logs_scope)

            logs
                .order(sort_order, id: :desc)
                .page(page)
                .per(per_page)
        end

        def find(id)
            logs_scope.find(id)
        end

        def kind
            requested_kind = query[:kind].to_s
            LOG_KINDS.include?(requested_kind) ? requested_kind : DEFAULT_KIND
        end

        def available_kinds
            LOG_KINDS
        end

        private

        def logs_scope
            return account_logs if kind == "account"

            user_logs
        end

        def account_logs
            audit_account.account_logs
        end

        def user_logs
            audit_account.user_logs
        end

        def audit_account
            current_user.account.audit
        end

        def apply_search(logs)
            term = query[:search].to_s.strip
            return logs if term.blank?

            # Build one case-insensitive condition from a fixed field allowlist;
            # the search text remains a bound value instead of becoming SQL.
            pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term.downcase)}%"
            conditions = SEARCH_FIELDS.map do |field|
                lower(log_table[field]).matches(pattern)
            end

            logs.where(conditions.reduce(:or))
        end

        def lower(attribute)
            Arel::Nodes::NamedFunction.new("LOWER", [ attribute ])
        end

        def sort_order
            direction = query.dig(:order, :dir).to_s.casecmp?("asc") ? :asc : :desc
            sort_column.public_send(direction)
        end

        def sort_column
            field = query.dig(:order, :by).to_s
            field = "created_at" unless %w[operation source actor_uid created_at].include?(field)

            log_table[field]
        end

        def log_table
            kind == "account" ? AccountLog.arel_table : UserLog.arel_table
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
