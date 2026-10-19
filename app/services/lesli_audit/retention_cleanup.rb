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
    # Applies the retention policy configured by the host application.
    #
    # Cleanup uses delete_all deliberately: analytics has no destroy callbacks,
    # while activity events are append-only during their retained lifetime. Each
    # relation is deleted in bounded primary-key batches and can be retried safely.
    class RetentionCleanup
        DEFAULT_BATCH_SIZE = 1_000

        ANALYTICS_MODELS = [
            LesliAudit::AccountDevice,
            LesliAudit::AccountRequest,
            LesliAudit::UserRequest
        ].freeze

        ACTIVITY_MODELS = [
            LesliAudit::AccountLog,
            LesliAudit::UserLog
        ].freeze

        def self.call(batch_size: DEFAULT_BATCH_SIZE, today: Date.current, now: Time.current)
            new(batch_size: batch_size, today: today, now: now).call
        end

        def initialize(batch_size:, today:, now:)
            @batch_size = positive_integer!(batch_size, :batch_size)
            @today = today.to_date
            @now = now
        end

        def call
            deleted = {}

            cleanup_journals(deleted)
            cleanup_group(
                deleted,
                ANALYTICS_MODELS,
                column: :date,
                cutoff: date_cutoff(:analytics_retention_days)
            )
            cleanup_group(
                deleted,
                ACTIVITY_MODELS,
                column: :created_at,
                cutoff: time_cutoff(:audit_retention_days)
            )

            deleted
        end

        private

        attr_reader :batch_size, :now, :today

        def cleanup_journals(deleted)
            retained_count = delete_with_cutoff(
                LesliAudit::UserJournal.retained.processed,
                :date,
                date_cutoff(:journal_retention_days)
            )
            transient_count = delete_with_cutoff(
                LesliAudit::UserJournal.transient.processed,
                :date,
                date_cutoff(:analytics_retention_days)
            )

            deleted[LesliAudit::UserJournal.table_name] = retained_count + transient_count
        end

        def cleanup_group(deleted, models, column:, cutoff:)
            models.each do |model|
                deleted[model.table_name] = delete_with_cutoff(model.all, column, cutoff)
            end
        end

        def delete_with_cutoff(relation, column, cutoff)
            return 0 unless cutoff

            relation
                .where(relation.klass.arel_table[column].lt(cutoff))
                .in_batches(of: batch_size)
                .delete_all
        end

        def date_cutoff(setting)
            days = retention_days(setting)
            today - days if days
        end

        def time_cutoff(setting)
            days = retention_days(setting)
            now - days.days if days
        end

        def retention_days(setting)
            value = Lesli.config.audit&.dig(setting)
            return if value.nil?

            positive_integer!(value, setting)
        end

        def positive_integer!(value, setting)
            valid_value = value.is_a?(Integer) || (value.is_a?(String) && value.match?(/\A[1-9]\d*\z/))
            raise ArgumentError unless valid_value

            integer = value.to_i
            return integer if integer.positive?

            raise ArgumentError, "#{setting} must be a positive integer or nil"
        rescue ArgumentError, TypeError
            raise ArgumentError, "#{setting} must be a positive integer or nil"
        end
    end
end
