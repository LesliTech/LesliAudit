require "test_helper"

module LesliAudit
    class LoggerInterfaceTest < ActiveSupport::TestCase
        include ActiveJob::TestHelper

        ControllerContext = Struct.new(:current_user, :request, :session) do
            include LesliAudit::LoggerInterface

            def controller_path
                "lesli_audit/reports"
            end

            def action_name
                "index"
            end
        end

        RequestContext = Struct.new(:request_id, :user_agent)

        setup do
            audit_account
            clear_enqueued_jobs
        end

        test "captures request context through the controller interface" do
            controller = ControllerContext.new(
                core_user,
                RequestContext.new("request-interface", "Test Browser"),
                { user_session_id: "session-interface" }
            )

            with_audit_config(enable_analytics: true, enable_journals: true) do
                assert_enqueued_with(job: LesliAudit::RequestAnalyticsJob) do
                    assert controller.log_requests
                end
            end

            journal = LesliAudit::UserJournal.find_by!(event_uid: "request-interface")
            assert_equal "lesli_audit/reports", journal.request_controller
            assert_equal "index", journal.request_action
            assert_equal "session-interface", journal.session_id
            assert_equal core_user, journal.user
        end
    end
end
