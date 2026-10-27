require "test_helper"

module LesliAudit
    class RequestServiceTest < ActiveSupport::TestCase
        test "administrator can review requests from every user in the account" do
            create_request(user: core_user, controller: "lesli/dashboard")
            create_request(user: same_account_core_user, controller: "lesli/users")

            requests = service_for(administrator(core_user)).index

            assert_equal 2, requests.total_count
            assert_equal [ core_user.id, same_account_core_user.id ].sort, requests.map(&:user_id).sort
        end

        test "regular user can review only their own requests" do
            create_request(user: core_user, controller: "lesli/dashboard")
            create_request(user: same_account_core_user, controller: "lesli/users")

            requests = service_for(regular_user(core_user)).index

            assert_equal 1, requests.total_count
            assert_equal [ core_user.id ], requests.map(&:user_id)
        end

        test "administrator never receives requests from another account" do
            create_request(user: core_user, controller: "lesli/dashboard")
            other_audit = LesliAudit::Account.find_or_create_by!(account: secondary_core_account) do |account|
                account.name = secondary_core_account.name
            end
            other_audit.user_requests.create!(
                user: secondary_core_user,
                request_controller: "lesli/admin",
                request_action: "index",
                request_count: 100,
                date: Date.current
            )

            requests = service_for(administrator(core_user)).index

            assert_equal 1, requests.total_count
            assert_equal [ "lesli/dashboard" ], requests.map(&:request_controller)
        end

        test "searches sorts and paginates through safe query options" do
            create_request(
                user: core_user,
                controller: "lesli/users",
                action: "index",
                count: 5
            )
            create_request(
                user: core_user,
                controller: "lesli/users",
                action: "show",
                count: 9
            )
            create_request(
                user: core_user,
                controller: "lesli/dashboard",
                action: "index",
                count: 20
            )

            first_page = service_for(
                regular_user(core_user),
                search: "USERS",
                pagination: { page: 1, perPage: 1 },
                order: { by: "count", dir: "desc" }
            ).index
            second_page = service_for(
                regular_user(core_user),
                search: "users",
                pagination: { page: 2, perPage: 1 },
                order: { by: "count", dir: "desc" }
            ).index

            assert_equal 2, first_page.total_count
            assert_equal 2, first_page.total_pages
            assert_equal 9, first_page.first.request_count
            assert_equal 5, second_page.first.request_count
        end

        test "caps requested page size and ignores unsupported sort columns" do
            create_request(user: core_user, controller: "lesli/dashboard")

            requests = service_for(
                regular_user(core_user),
                pagination: { page: 0, perPage: 1_000 },
                order: { by: "account_id; DROP TABLE users", dir: "sideways" }
            ).index

            assert_equal 1, requests.current_page
            assert_equal 100, requests.limit_value
            assert_equal [ "lesli/dashboard" ], requests.map(&:request_controller)
        end

        private

        def create_request(user:, controller:, action: "index", count: 1)
            audit_account.user_requests.create!(
                user:,
                request_controller: controller,
                request_action: action,
                request_count: count,
                date: Date.current
            )
        end

        def service_for(user, overrides = {})
            query = {
                search: nil,
                pagination: { page: 1, perPage: 12 },
                order: { by: "date", dir: "desc" }
            }.deep_merge(overrides)

            LesliAudit::RequestService.new(user, query)
        end

        def administrator(user)
            user.define_singleton_method(:has_roles?) do |*roles|
                roles.include?("admin")
            end
            user
        end

        def regular_user(user)
            user.define_singleton_method(:has_roles?) { |*_roles| false }
            user
        end
    end
end
