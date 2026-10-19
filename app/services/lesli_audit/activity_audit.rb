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
    # Writes durable business and security events. Unlike request analytics,
    # this entry point never rescues persistence errors: an auditable operation
    # must fail when its event cannot be stored.
    class ActivityAudit
        class MissingAccount < StandardError; end

        def self.record_account!(account:, actor: nil, **attributes)
            return unless enabled?

            new(account: account, actor: actor, **attributes).record_account!
        end

        def self.record_user!(user:, **attributes)
            return unless enabled?

            new(account: user&.account, actor: user, **attributes).record_user!
        end

        def self.enabled?
            Lesli.config.audit&.dig(:enable_logs) == true
        end

        def initialize(
            account:,
            actor: nil,
            engine: nil,
            source: nil,
            action: nil,
            operation: nil,
            description: nil,
            session_id: nil,
            subject: nil
        )
            @audit_account = resolve_audit_account(account)
            @actor = actor
            @engine = identifier(engine)
            @source = identifier(source)
            @action = identifier(action)
            @operation = identifier(operation.presence || action.presence)
            @description = description
            @session_id = session_id.presence
            @subject = subject

            raise ArgumentError, "operation is required" if @operation.blank?
        end

        def record_account!
            audit_account.account_logs.create!(event_attributes.merge(user: actor))
        end

        def record_user!
            raise ArgumentError, "user is required" unless actor

            audit_account.user_logs.create!(event_attributes.merge(user: actor))
        end

        private

        attr_reader :actor, :audit_account, :subject

        def resolve_audit_account(account)
            resolved = account if account.is_a?(LesliAudit::Account)
            resolved ||= account&.audit if account&.respond_to?(:audit)

            return resolved if resolved

            raise MissingAccount, "LesliAudit account is required"
        end

        # Keep event metadata deliberately small. Request parameters and other
        # unfiltered payloads are not accepted by this API.
        def event_attributes
            {
                engine: @engine,
                source: @source,
                action: @action,
                operation: @operation,
                description: @description,
                session_id: @session_id,
                actor_uid: actor_uid,
                subject_type: subject&.class&.name,
                subject_id: subject&.id
            }
        end

        def actor_uid
            actor.uid if actor&.respond_to?(:uid)
        end

        def identifier(value)
            return if value.nil?
            return value.name if value.respond_to?(:name) && value.name.present?

            value.to_s
        end
    end
end
