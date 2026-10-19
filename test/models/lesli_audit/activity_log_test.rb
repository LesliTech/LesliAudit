require "test_helper"

module LesliAudit
    class ActivityLogTest < ActiveSupport::TestCase
        test "requires an operation" do
            user_log = audit_account.user_logs.new(user: core_user)
            account_log = audit_account.account_logs.new(user: core_user)

            assert_not user_log.valid?
            assert_not account_log.valid?
            assert_includes user_log.errors[:operation], "can't be blank"
            assert_includes account_log.errors[:operation], "can't be blank"
        end

        test "persisted activity events are append only" do
            event = audit_account.user_logs.create!(
                user: core_user,
                operation: "session_creation_succeeded"
            )

            assert_predicate event, :readonly?
            assert_raises(ActiveRecord::ReadOnlyRecord) do
                event.update!(description: "changed")
            end
        end
    end
end

