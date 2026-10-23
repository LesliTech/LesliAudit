require "test_helper"

module LesliAudit
    class UserServiceTest < ActiveSupport::TestCase
        test "working hours include retained request journals" do
            audit_account.user_journals.create!(
                event_uid: "working-hours-request",
                request_controller: "lesli_audit/reports",
                request_action: "index",
                date: Date.current,
                session_id: "working-hours-session",
                user: core_user
            )

            activity = LesliAudit::UserService
                .new(core_user)
                .working_hours
                .find { |record| record[:user_id] == core_user.id }

            assert activity
            assert_equal core_user.email, activity[:user_email]
            assert_equal 1, activity[:requests].to_i
            assert activity[:first_activity].present?
            assert activity[:last_activity].present?
        end
    end
end
