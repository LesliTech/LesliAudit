=begin

Lesli

Copyright (c) 2026, Lesli Technologies, S. A.

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

Made with ♥ by LesliTech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end

module LesliAudit
    module LoggerInterface
        def get_user_agent
            LesliAudit::UserAgentParser.parse(request.user_agent)
        end

        def log_requests
            return unless Lesli.config.audit.dig(:enable_analytics)
            return unless current_user
            log_account_requests
            log_user_requests
            log_user_journal
        end

        def log_devices
            return unless Lesli.config.audit.dig(:enable_analytics)
            return unless current_user

            user_agent = get_user_agent()

            # Try to save a unique record for this request configuration
            current_user.account.audit.account_devices.upsert(
                {
                    date: Date2.new.date.to_s,
                    :agent_platform => user_agent&.dig(:platform) || "unknown",
                    :agent_browser => user_agent&.dig(:browser) || "unknown",
                    :agent_device => user_agent&.dig(:device) || "unknown",
                    :agent_count => 1
                },

                # group of columns to consider a request as unique
                unique_by: :lesli_audit_devices_index,

                # if request id is not unique
                #   - increase the counter for this configuration
                #   - update the datetime of the last request
                on_duplicate: Arel.sql(
                    "agent_count = lesli_audit_account_devices.agent_count + 1, " \
                    "updated_at = CURRENT_TIMESTAMP"
                )
            )
        end

        private 

        def log_account_requests

            # Try to save a unique record for this request configuration
            current_user.account.audit.account_requests.upsert(
                {
                    request_controller: controller_path,
                    request_action: action_name,
                    request_count: 1,
                    date: Date2.new.date.to_s
                },

                # group of columns to consider a request as unique
                unique_by: :lesli_audit_account_requests_index,

                # if request id is not unique, increase the counter for this configuration
                on_duplicate: Arel.sql(
                    "request_count = lesli_audit_account_requests.request_count + 1, " \
                    "updated_at = CURRENT_TIMESTAMP"
                )
            )
        end

        # Track all user activity
        # this is disabled by default in the settings file
        def log_user_requests
            return unless session[:user_session_id]

            # Try to save a unique record for this request configuration
            current_user.account.audit.user_requests.upsert(
                {
                    request_controller: controller_path,
                    request_action: action_name,
                    session_id: session[:user_session_id],
                    user_id: current_user.id,
                    date: Date2.new.date.to_s,
                    request_count: 1
                },

                # group of columns to consider a request as unique
                unique_by: :lesli_audit_user_requests_index,

                # if request id is not unique
                #   - increase the counter for this configuration
                #   - update the datetime of the last request
                on_duplicate: Arel.sql(
                    "request_count = lesli_audit_user_requests.request_count + 1, " \
                    "updated_at = CURRENT_TIMESTAMP"
                )
            )
        end

        def log_user_journal
            return unless Lesli.config.audit.dig(:enable_journals)
            current_user.account.audit.user_journals.create({
                request_controller: controller_path,
                request_action: action_name,
                session_id: session[:user_session_id],
                user_id: current_user.id,
                date: Date2.new.date.to_s,
                processed_at: Time.current
            })
        end

        # Track specific account activity
        # this is disabled by default in the settings file
        def log_account_activity(system_module, system_process, title = nil, payload = nil, description = nil)
            # return unless Rails.application.config.lesli.dig(:security, :enable_analytics)

            # account = Account.first

            # account.activities.create({
            #     system_module:,
            #     system_process:,
            #     description:,
            #     payload:,
            #     title:
            # })
        end
    end
end
