require "test_helper"

module LesliAudit
    class ActivityAuditTest < ActiveSupport::TestCase
        setup do
            audit_account
        end

        test "records an allowlisted user event with immutable actor and subject snapshots" do
            with_audit_config(enable_logs: true) do
                event = LesliAudit::ActivityAudit.record_user!(
                    user: core_user,
                    engine: LesliAudit,
                    source: "TicketsController",
                    action: "close",
                    operation: "ticket_closed",
                    description: "Ticket closed successfully",
                    session_id: 123,
                    subject: core_account
                )

                assert_equal audit_account, event.account
                assert_equal core_user, event.user
                assert_equal "LesliAudit", event.engine
                assert_equal "TicketsController", event.source
                assert_equal "close", event.action
                assert_equal "ticket_closed", event.operation
                assert_equal "Ticket closed successfully", event.description
                assert_equal "123", event.session_id
                assert_equal core_user.uid, event.actor_uid
                assert_equal "Lesli::Account", event.subject_type
                assert_equal core_account.id, event.subject_id
            end
        end

        test "records account events with an optional actor" do
            with_audit_config(enable_logs: true) do
                event = LesliAudit::ActivityAudit.record_account!(
                    account: core_account,
                    actor: core_user,
                    operation: :account_initialized
                )

                assert_equal "account_initialized", event.operation
                assert_equal core_user.uid, event.actor_uid
                assert_equal audit_account, event.account
            end
        end

        test "is a no-op when activity logs are disabled" do
            with_audit_config(enable_logs: false) do
                assert_no_difference -> { LesliAudit::UserLog.count } do
                    assert_nil LesliAudit::ActivityAudit.record_user!(
                        user: core_user,
                        operation: "ignored"
                    )
                end
            end
        end

        test "rejects events without an audit account or operation" do
            with_audit_config(enable_logs: true) do
                assert_raises(LesliAudit::ActivityAudit::MissingAccount) do
                    LesliAudit::ActivityAudit.record_account!(
                        account: Lesli::Account.new,
                        operation: "missing_tenant"
                    )
                end

                assert_raises(ArgumentError) do
                    LesliAudit::ActivityAudit.record_user!(user: core_user)
                end
            end
        end
    end
end

