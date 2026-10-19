require "test_helper"

module LesliAudit
    class RetentionCleanupTest < ActiveSupport::TestCase
        TODAY = Date.new(2026, 10, 18)
        NOW = Time.zone.local(2026, 10, 18, 12, 0, 0)

        test "deletes expired rows while preserving cutoffs and pending journals" do
            retained_old = create_journal("retained-old", date: TODAY - 11, retain: true, processed: true)
            retained_cutoff = create_journal("retained-cutoff", date: TODAY - 10, retain: true, processed: true)
            transient_old = create_journal("transient-old", date: TODAY - 21, retain: false, processed: true)
            pending_old = create_journal("pending-old", date: TODAY - 100, retain: true, processed: false)

            request_old = audit_account.account_requests.create!(
                request_controller: "reports",
                request_action: "old",
                request_count: 1,
                date: TODAY - 21
            )
            request_cutoff = audit_account.account_requests.create!(
                request_controller: "reports",
                request_action: "cutoff",
                request_count: 1,
                date: TODAY - 20
            )
            log_old = audit_account.user_logs.create!(
                user: core_user,
                operation: "old_event",
                created_at: NOW - 31.days
            )
            log_cutoff = audit_account.user_logs.create!(
                user: core_user,
                operation: "cutoff_event",
                created_at: NOW - 30.days
            )

            with_audit_config(
                journal_retention_days: 10,
                analytics_retention_days: 20,
                audit_retention_days: 30
            ) do
                deleted = LesliAudit::RetentionCleanup.call(
                    batch_size: 2,
                    today: TODAY,
                    now: NOW
                )

                assert_equal 2, deleted[LesliAudit::UserJournal.table_name]
                assert_equal 1, deleted[LesliAudit::AccountRequest.table_name]
                assert_equal 1, deleted[LesliAudit::UserLog.table_name]
            end

            assert_not LesliAudit::UserJournal.exists?(retained_old.id)
            assert_not LesliAudit::UserJournal.exists?(transient_old.id)
            assert LesliAudit::UserJournal.exists?(retained_cutoff.id)
            assert LesliAudit::UserJournal.exists?(pending_old.id)
            assert_not LesliAudit::AccountRequest.exists?(request_old.id)
            assert LesliAudit::AccountRequest.exists?(request_cutoff.id)
            assert_not LesliAudit::UserLog.exists?(log_old.id)
            assert LesliAudit::UserLog.exists?(log_cutoff.id)
        end

        test "nil retention skips that data class" do
            event = audit_account.user_logs.create!(
                user: core_user,
                operation: "preserved",
                created_at: NOW - 10.years
            )

            with_audit_config(
                journal_retention_days: nil,
                analytics_retention_days: nil,
                audit_retention_days: nil
            ) do
                deleted = LesliAudit::RetentionCleanup.call(today: TODAY, now: NOW)

                assert_equal 0, deleted.values.sum
            end

            assert LesliAudit::UserLog.exists?(event.id)
        end

        test "rejects invalid retention and batch settings" do
            with_audit_config(analytics_retention_days: 0) do
                error = assert_raises(ArgumentError) do
                    LesliAudit::RetentionCleanup.call(today: TODAY, now: NOW)
                end

                assert_equal "analytics_retention_days must be a positive integer or nil", error.message
            end

            error = assert_raises(ArgumentError) do
                LesliAudit::RetentionCleanup.call(batch_size: 0, today: TODAY, now: NOW)
            end

            assert_equal "batch_size must be a positive integer or nil", error.message
        end

        private

        def create_journal(event_uid, date:, retain:, processed:)
            audit_account.user_journals.create!(
                event_uid: event_uid,
                request_controller: ("reports" if retain),
                request_action: ("index" if retain),
                date: date,
                retain: retain,
                analytics_enabled: true,
                processed_at: (NOW if processed),
                user: (core_user if retain)
            )
        end
    end
end

