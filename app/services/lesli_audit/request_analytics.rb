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

require "securerandom"

module LesliAudit
    # Captures request traffic without changing the outcome of the request.
    #
    # The controller stores one small durable event and enqueues its processing.
    # The event UID makes duplicate callbacks and job retries idempotent.
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

        def self.process!(journal_id)
            journal = LesliAudit::UserJournal.find_by(id: journal_id)
            return unless journal

            Processor.new(journal).process!
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

        def initialize(user:, controller:, action:, event_uid: nil, session_id: nil, user_agent: nil, date: Date.current)
            @user = user
            @controller = controller.to_s
            @action = action.to_s
            @event_uid = event_uid.presence || SecureRandom.uuid
            @session_id = session_id.presence&.to_s
            @user_agent = user_agent.to_s
            @date = date.to_date
        end

        def capture
            analytics_enabled = analytics_enabled?
            journals_enabled = journals_enabled?

            return unless analytics_enabled || journals_enabled
            return unless audit_account

            journal = create_event(
                analytics_enabled: analytics_enabled,
                retain: journals_enabled
            )

            enqueue(journal)

            true
        end

        private

        attr_reader :action, :controller, :date, :event_uid, :session_id, :user, :user_agent

        def analytics_enabled?
            Lesli.config.audit&.dig(:enable_analytics) == true
        end

        def journals_enabled?
            Lesli.config.audit&.dig(:enable_journals) == true
        end

        def audit_account
            @audit_account ||= user&.account&.audit
        end

        def create_event(analytics_enabled:, retain:)
            agent = LesliAudit::UserAgentParser.parse(user_agent)

            audit_account.user_journals.create_or_find_by!(event_uid: event_uid) do |journal|
                journal.assign_attributes(
                    request_dimensions.merge(
                        user_id: user.id,
                        session_id: session_id,
                        analytics_enabled: analytics_enabled,
                        retain: retain,
                        agent_platform: agent_value(agent[:platform]),
                        agent_browser: agent_value(agent[:browser]),
                        agent_device: agent_value(agent[:device])
                    )
                )
            end
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

        def enqueue(journal)
            LesliAudit::RequestAnalyticsJob.perform_later(journal.id)
        rescue StandardError => error
            # The durable pending row remains available to the recovery task.
            self.class.report(error, operation: :enqueue)
            nil
        end

        # Executes all derived writes and the processed marker atomically. A
        # duplicate job blocks on the row lock and then observes processed_at.
        class Processor
            ACCOUNT_REQUEST_INCREMENT = Arel.sql(
                "request_count = lesli_audit_account_requests.request_count + 1, " \
                "updated_at = CURRENT_TIMESTAMP"
            ).freeze

            USER_REQUEST_INCREMENT = Arel.sql(
                "request_count = lesli_audit_user_requests.request_count + 1, " \
                "updated_at = CURRENT_TIMESTAMP"
            ).freeze

            DEVICE_REQUEST_INCREMENT = Arel.sql(
                "agent_count = lesli_audit_account_devices.agent_count + 1, " \
                "updated_at = CURRENT_TIMESTAMP"
            ).freeze

            def initialize(journal)
                @journal = journal
            end

            def process!
                journal.with_lock do
                    return false if journal.processed_at?

                    capture_traffic if journal.analytics_enabled?
                    finish_event
                end

                true
            end

            private

            attr_reader :journal

            def capture_traffic
                increment_account_requests
                increment_user_requests if journal.user_id
                increment_device_requests
            end

            def increment_account_requests
                journal.account.account_requests.upsert(
                    request_dimensions.merge(request_count: 1),
                    unique_by: :lesli_audit_account_requests_index,
                    on_duplicate: ACCOUNT_REQUEST_INCREMENT
                )
            end

            def increment_user_requests
                journal.account.user_requests.upsert(
                    request_dimensions.merge(
                        session_id: journal.session_id,
                        user_id: journal.user_id,
                        request_count: 1
                    ),
                    unique_by: :lesli_audit_user_requests_index,
                    on_duplicate: USER_REQUEST_INCREMENT
                )
            end

            def increment_device_requests
                journal.account.account_devices.upsert(
                    {
                        date: journal.date,
                        agent_platform: journal.agent_platform,
                        agent_browser: journal.agent_browser,
                        agent_device: journal.agent_device,
                        agent_count: 1
                    },
                    unique_by: :lesli_audit_devices_index,
                    on_duplicate: DEVICE_REQUEST_INCREMENT
                )
            end

            def request_dimensions
                {
                    request_controller: journal.request_controller,
                    request_action: journal.request_action,
                    date: journal.date
                }
            end

            def finish_event
                journal.processed_at = Time.current
                scrub_transient_payload unless journal.retain?
                journal.save!
            end

            # When journals are disabled, retain only the event identity needed
            # for deduplication. Request and agent dimensions already live in the
            # aggregates and are removed from the inbox row.
            def scrub_transient_payload
                journal.assign_attributes(
                    user: nil,
                    session_id: nil,
                    request_controller: nil,
                    request_action: nil,
                    agent_platform: nil,
                    agent_browser: nil,
                    agent_device: nil
                )
            end
        end
    end
end
