require "test_helper"

module LesliAudit
    class LogsControllerTest < ActiveSupport::TestCase
        test "assigns account events and exposes both event types" do
            account_log = audit_account.account_logs.create!(
                user: core_user,
                operation: "account_initialized"
            )
            user = core_user
            controller = controller_for(user, kind: "account")

            controller.index

            logs = controller.instance_variable_get(:@logs)
            assert_equal [ account_log.id ], logs[:records].map(&:id)
            assert_equal "account", controller.instance_variable_get(:@log_kind)
            assert_equal %w[user account], controller.instance_variable_get(:@available_log_kinds)
        end

        test "loads a read-only event detail through the scoped service" do
            user_log = audit_account.user_logs.create!(
                user: core_user,
                operation: "profile_updated"
            )
            controller = controller_for(core_user, kind: "user", id: user_log.id)

            controller.send(:set_log)

            assert_equal user_log, controller.instance_variable_get(:@log)
            assert_predicate controller.instance_variable_get(:@log), :readonly?
        end

        private

        def controller_for(user, params = {})
            query = {
                search: nil,
                pagination: { page: 1, perPage: 12 },
                order: { by: "created_at", dir: "desc" }
            }
            controller = LesliAudit::LogsController.new
            controller.params = ActionController::Parameters.new(params)
            controller.define_singleton_method(:current_user) { user }
            controller.define_singleton_method(:query) { query }
            controller
        end
    end
end
