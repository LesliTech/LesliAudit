require "test_helper"

module LesliAudit
    class AccountTest < ActiveSupport::TestCase
        test "belongs to the core account" do
            reflection = LesliAudit::Account.reflect_on_association(:account)

            assert_equal :belongs_to, reflection.macro
            assert_equal "Lesli::Account", reflection.class_name
            assert_equal :audit, reflection.options[:inverse_of]
        end

        test "owns every account-scoped audit collection" do
            expected = {
                account_logs: LesliAudit::AccountLog,
                account_devices: LesliAudit::AccountDevice,
                account_requests: LesliAudit::AccountRequest,
                user_logs: LesliAudit::UserLog,
                user_journals: LesliAudit::UserJournal,
                user_requests: LesliAudit::UserRequest,
                visitor_rollups: LesliAudit::VisitorRollup,
                visitor_breakdowns: LesliAudit::VisitorBreakdown
            }

            expected.each do |association, model|
                reflection = LesliAudit::Account.reflect_on_association(association)

                assert_equal :has_many, reflection.macro
                assert_equal model, reflection.klass
                assert_equal :delete_all, reflection.options[:dependent]
            end
        end

        test "hard deletion removes both account and user activity events" do
            account_log = audit_account.account_logs.create!(
                user: core_user,
                operation: "account_initialized"
            )
            user_log = audit_account.user_logs.create!(
                user: core_user,
                operation: "profile_updated"
            )

            audit_account.destroy!

            assert_not LesliAudit::AccountLog.exists?(account_log.id)
            assert_not LesliAudit::UserLog.exists?(user_log.id)
        end
    end
end
