require "test_helper"

module LesliAudit
    class RequestAnalyticsTest < ActiveSupport::TestCase
        include ActiveJob::TestHelper

        USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
            "AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36"

        setup do
            audit_account
            clear_enqueued_jobs
            clear_performed_jobs
        end

        test "captures one durable journal and counts a duplicated event once" do
            with_audit_config(enable_analytics: true, enable_journals: true) do
                assert_difference -> { LesliAudit::UserJournal.count }, 1 do
                    perform_enqueued_jobs do
                        2.times { capture(event_uid: "request-idempotent") }
                    end
                end

                journal = LesliAudit::UserJournal.find_by!(event_uid: "request-idempotent")

                assert_predicate journal, :processed_at?
                assert_predicate journal, :retain?
                assert_equal core_user, journal.user
                assert_equal "reports", journal.request_controller
                assert_equal "index", journal.request_action
                assert_equal 1, LesliAudit::AccountRequest.sum(:request_count)
                assert_equal 1, LesliAudit::UserRequest.sum(:request_count)
                assert_equal 1, LesliAudit::AccountDevice.sum(:agent_count)
            end
        end

        test "increments aggregates for distinct events with the same dimensions" do
            with_audit_config(enable_analytics: true, enable_journals: true) do
                perform_enqueued_jobs do
                    capture(event_uid: "request-first")
                    capture(event_uid: "request-second")
                end

                assert_equal 2, LesliAudit::AccountRequest.sum(:request_count)
                assert_equal 2, LesliAudit::UserRequest.sum(:request_count)
                assert_equal 2, LesliAudit::AccountDevice.sum(:agent_count)
            end
        end

        test "scrubs individual request dimensions when journals are disabled" do
            with_audit_config(enable_analytics: true, enable_journals: false) do
                perform_enqueued_jobs { capture(event_uid: "request-transient") }

                journal = LesliAudit::UserJournal.find_by!(event_uid: "request-transient")

                assert_predicate journal, :processed_at?
                assert_not journal.retain?
                assert_nil journal.user_id
                assert_nil journal.session_id
                assert_nil journal.request_controller
                assert_nil journal.request_action
                assert_nil journal.agent_platform
                assert_nil journal.agent_browser
                assert_nil journal.agent_device
                assert_equal 1, LesliAudit::AccountRequest.sum(:request_count)
            end
        end

        test "retains a journal without creating aggregates when analytics are disabled" do
            with_audit_config(enable_analytics: false, enable_journals: true) do
                perform_enqueued_jobs { capture(event_uid: "request-journal-only") }

                journal = LesliAudit::UserJournal.find_by!(event_uid: "request-journal-only")

                assert_predicate journal, :processed_at?
                assert_predicate journal, :retain?
                assert_not journal.analytics_enabled?
                assert_equal "reports", journal.request_controller
                assert_equal 0, LesliAudit::AccountRequest.count
                assert_equal 0, LesliAudit::UserRequest.count
                assert_equal 0, LesliAudit::AccountDevice.count
            end
        end

        test "does not capture when analytics and journals are disabled" do
            with_audit_config(enable_analytics: false, enable_journals: false) do
                assert_no_enqueued_jobs do
                    assert_no_difference -> { LesliAudit::UserJournal.count } do
                        assert_nil capture(event_uid: "request-disabled")
                    end
                end
            end
        end

        test "fails open when the user has no audit account" do
            other_account = secondary_core_account
            other_user = secondary_core_user
            assert_equal other_account, other_user.account
            assert_nil other_account.audit

            with_audit_config(enable_analytics: true, enable_journals: true) do
                assert_no_enqueued_jobs do
                    assert_nil LesliAudit::RequestAnalytics.capture(
                        user: other_user,
                        controller: "reports",
                        action: "index",
                        event_uid: "request-no-audit"
                    )
                end
            end
        end

        private

        def capture(event_uid:)
            LesliAudit::RequestAnalytics.capture(
                user: core_user,
                controller: "reports",
                action: "index",
                event_uid: event_uid,
                session_id: "session-1",
                user_agent: USER_AGENT,
                date: Date.new(2026, 10, 18)
            )
        end
    end
end

