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

require "device_detector"

module LesliAudit
    # Captures request traffic without changing the outcome of the request.
    #
    # Analytics is intentionally best effort: every write is isolated, reported,
    # and allowed to fail independently from the other metrics.
    class RequestAnalytics
        UNKNOWN_AGENT = "unknown"

        # Public entry point used by LoggerInterface. This final rescue also
        # covers failures that happen before an individual write can start.
        def self.capture(**attributes)
            new(**attributes).capture
        rescue StandardError => error
            report(error, operation: :capture)
            nil
        end

        # Reporting is fail-open too: a broken error subscriber must never turn
        # an analytics failure into an application failure.
        def self.report(error, operation:)
            Rails.error.report(
                error,
                handled: true,
                severity: :warning,
                context: {
                    component: name,
                    operation: operation
                }
            )
        rescue StandardError
            nil
        end

        def initialize(user:, controller:, action:, session_id: nil, user_agent: nil, date: Date.current)
            @user = user
            @controller = controller.to_s
            @action = action.to_s
            @session_id = session_id.presence
            @user_agent = user_agent.to_s
            @date = date
        end

        def capture
            analytics_enabled = analytics_enabled?
            journals_enabled = journals_enabled?

            return unless analytics_enabled || journals_enabled
            return unless audit_account

            capture_traffic if analytics_enabled
            capture_journal if journals_enabled && session_id

            true
        end

        private

        attr_reader :action, :controller, :date, :session_id, :user, :user_agent

        def analytics_enabled?
            Lesli.config.audit&.dig(:enable_analytics) == true
        end

        def journals_enabled?
            Lesli.config.audit&.dig(:enable_journals) == true
        end

        def audit_account
            @audit_account ||= user&.account&.audit
        end

        # These writes do not share a transaction. Losing one metric must not
        # prevent the remaining metrics from being captured.
        def capture_traffic
            safe_write(:account_request) { increment_account_requests }
            safe_write(:user_request) { increment_user_requests } if session_id
            safe_write(:device) { increment_device_requests }
        end

        def capture_journal
            safe_write(:journal) do
                audit_account.user_journals.create!(
                    request_dimensions.merge(
                        session_id: session_id,
                        user_id: user.id
                    )
                )
            end
        end

        def increment_account_requests
            audit_account.account_requests.upsert(
                request_dimensions.merge(request_count: 1),
                unique_by: :lesli_audit_account_requests_index,
                on_duplicate: increment_counter(:lesli_audit_account_requests, :request_count)
            )
        end

        # User metrics retain the opaque session identifier when one is
        # available, but never require a LesliShield database relationship.
        def increment_user_requests
            audit_account.user_requests.upsert(
                request_dimensions.merge(
                    session_id: session_id,
                    user_id: user.id,
                    request_count: 1
                ),
                unique_by: :lesli_audit_user_requests_index,
                on_duplicate: increment_counter(:lesli_audit_user_requests, :request_count)
            )
        end

        def increment_device_requests
            agent = DeviceDetector.new(user_agent)

            audit_account.account_devices.upsert(
                {
                    date: date,
                    agent_platform: agent_value(agent.os_name),
                    agent_browser: agent_value(agent.name),
                    agent_device: agent_value(agent.device_type),
                    agent_count: 1
                },
                unique_by: :lesli_audit_devices_index,
                on_duplicate: increment_counter(:lesli_audit_account_devices, :agent_count)
            )
        end

        def request_dimensions
            {
                request_controller: controller,
                request_action: action,
                date: date
            }
        end

        # Only normalized categories are stored; the raw user-agent string is
        # discarded after DeviceDetector parses it.
        def agent_value(value)
            value.presence || UNKNOWN_AGENT
        end

        # The database performs the increment atomically so concurrent requests
        # cannot overwrite each other's counters.
        def increment_counter(table, counter)
            Arel.sql(
                "#{counter} = #{table}.#{counter} + 1, updated_at = #{LesliDate::Compatibility.db_now}"
            )
        end

        def safe_write(operation)
            yield
        rescue StandardError => error
            self.class.report(error, operation: operation)
            nil
        end
    end
end
