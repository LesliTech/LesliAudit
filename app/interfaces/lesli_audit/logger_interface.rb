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
    module LoggerInterface
        def get_user_agent(as_string=true)

            http_user_agent = request.env["HTTP_USER_AGENT"]

            # parse user agent
            user_agent = UserAgent.parse(http_user_agent)

            user_agent_version = user_agent.version.to_a.first(2).join(".")

            # return user agent as object
            if as_string == false
                return {
                    platform: user_agent.platform,
                    os: user_agent.os,
                    browser: user_agent.browser,
                    version: user_agent_version
                }
            end

            # return user agent info as string
            "#{user_agent.platform} #{user_agent.os} - #{user_agent.browser} #{user_agent_version}"
        end

        def log_requests
            log_account_requests
            log_user_requests
        end 

        def log_account_requests
            return unless Lesli.config.security.dig(:enable_analytics)
            return unless defined?(LesliAudit)
            return unless current_user

            # Try to save a unique record for this request configuration
            current_user.account.audit.account_requests.upsert(
                {
                    request_controller: controller_path,
                    request_action: action_name,
                    request_count: 1,
                    created_at: Date2.new.date.to_s
                },
                
                # group of columns to consider a request as unique
                unique_by: %i[request_controller request_action created_at account_id],

                # if request id is not unique, increase the counter for this configuration
                on_duplicate: Arel.sql("request_count = lesli_audit_account_requests.request_count + 1")
            )
        end

        # Track all user activity
        # this is disabled by default in the settings file
        def log_user_requests
            return unless Lesli.config.security.dig(:enable_analytics)
            return unless defined?(LesliAudit)
            return unless current_user
            return unless session[:user_session_id]
            
            # Try to save a unique record for this request configuration
            current_user.account.audit.user_requests.upsert(
                {
                    request_controller: controller_path,
                    request_action: action_name,
                    session_id: session[:user_session_id],
                    user_id: current_user.id,
                    request_count: 1,
                    created_at: Date2.new.date.to_s
                },
                        
                # group of columns to consider a request as unique
                unique_by: %i[request_controller request_action created_at user_id session_id],

                # if request id is not unique
                #   - increase the counter for this configuration
                #   - update the datetime of the last request
                on_duplicate: Arel.sql(
                    'request_count = lesli_audit_user_requests.request_count + 1'
                )
            )
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
