require "test_helper"

module LesliAudit
    class LoggerInterfaceTest < ActiveSupport::TestCase
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
        end

        test "logs request counters without logging a device" do
            with_audit_config(enable_analytics: true, enable_journals: false) do
                controller_context.log_requests
            end

            assert_equal 1, LesliAudit::AccountRequest.sum(:request_count)
            assert_equal 1, LesliAudit::UserRequest.sum(:request_count)
            assert_equal 0, LesliAudit::UserJournal.count
            assert_equal 0, LesliAudit::AccountDevice.count
        end

        test "logs an individual journal when analytics and journals are enabled" do
            with_audit_config(enable_analytics: true, enable_journals: true) do
                assert_difference -> { LesliAudit::UserJournal.count }, 1 do
                    assert_difference -> { LesliAudit::AccountRequest.sum(:request_count) }, 1 do
                        assert_difference -> { LesliAudit::UserRequest.sum(:request_count) }, 1 do
                            controller_context.log_requests
                        end
                    end
                end
            end

            journal = LesliAudit::UserJournal.order(:id).last

            assert_equal "request-interface", journal.event_uid
            assert_equal "lesli_audit/reports", journal.request_controller
            assert_equal "index", journal.request_action
            assert_equal "session-interface", journal.session_id
            assert_equal core_user, journal.user
            assert_equal audit_account, journal.account
            assert_equal Date2.new.get.to_date, journal.date
            assert journal.retain?
        end

        test "the analytics switch disables request counters and journals" do
            with_audit_config(enable_analytics: false, enable_journals: true) do
                assert_no_difference -> { LesliAudit::AccountRequest.count } do
                    assert_no_difference -> { LesliAudit::UserRequest.count } do
                        assert_no_difference -> { LesliAudit::UserJournal.count } do
                            controller_context.log_requests
                        end
                    end
                end
            end
        end

        test "logs a device only when explicitly requested by the login flow" do
            original_timestamp = 2.days.ago

            with_audit_config(enable_analytics: true, enable_journals: false) do
                controller_context.log_requests
                assert_equal 0, LesliAudit::AccountDevice.count

                controller_context.log_devices
                LesliAudit::AccountDevice.first.update_column(:updated_at, original_timestamp)
                controller_context.log_devices
            end

            device = LesliAudit::AccountDevice.sole
            assert_equal 2, device.agent_count
            assert_operator device.updated_at, :>, original_timestamp
        end

        private

        def controller_context
            @controller_context ||= ControllerContext.new(
                core_user,
                RequestContext.new("request-interface", "Test Browser"),
                { user_session_id: "session-interface" }
            )
        end
    end
end
