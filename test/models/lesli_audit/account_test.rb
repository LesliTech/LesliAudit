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
                user_requests: LesliAudit::UserRequest
            }

            expected.each do |association, model|
                reflection = LesliAudit::Account.reflect_on_association(association)

                assert_equal :has_many, reflection.macro
                assert_equal model, reflection.klass
                assert_equal :delete_all, reflection.options[:dependent]
            end
        end
    end
end

