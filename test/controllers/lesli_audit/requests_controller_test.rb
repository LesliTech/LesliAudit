require "test_helper"

module LesliAudit
    class RequestsControllerTest < ActiveSupport::TestCase
        test "assigns the paginated account request report for an administrator" do
            audit_account.user_requests.create!(
                user: same_account_core_user,
                request_controller: "lesli/users",
                request_action: "index",
                request_count: 3,
                date: Date.current
            )
            user = core_user
            user.define_singleton_method(:has_roles?) do |*roles|
                roles.include?("admin")
            end
            query = {
                search: nil,
                pagination: { page: 1, perPage: 12 },
                order: { by: "date", dir: "desc" }
            }
            controller = LesliAudit::RequestsController.new
            controller.define_singleton_method(:current_user) { user }
            controller.define_singleton_method(:query) { query }

            controller.index

            requests = controller.instance_variable_get(:@requests)
            assert_equal 1, requests.dig(:pagination, :total)
            assert_equal same_account_core_user.email, requests[:records].first.user_email
        end
    end
end
