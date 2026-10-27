require "test_helper"

module LesliAudit
    class LogServiceTest < ActiveSupport::TestCase
        test "authorized user can read every user event in the account" do
            own_log = create_user_log(user: core_user, operation: "profile_updated")
            colleague_log = create_user_log(user: same_account_core_user, operation: "role_assigned")

            logs = service_for(core_user).index

            assert_equal [ own_log.id, colleague_log.id ].sort, logs.map(&:id).sort
        end

        test "authorized user can read account events separately from user events" do
            account_log = create_account_log(operation: "account_initialized")
            create_user_log(user: core_user, operation: "profile_updated")
            service = service_for(core_user, kind: "account")

            logs = service.index

            assert_equal [ account_log.id ], logs.map(&:id)
            assert_equal %w[user account], service.available_kinds
        end

        test "queries never return logs from another account" do
            own_log = create_user_log(user: core_user, operation: "profile_updated")
            other_audit = audit_account_for(secondary_core_account)
            foreign_log = other_audit.user_logs.create!(
                user: secondary_core_user,
                operation: "foreign_event"
            )

            service = service_for(core_user)
            logs = service.index

            assert_equal [ own_log.id ], logs.map(&:id)
            assert_raises(ActiveRecord::RecordNotFound) { service.find(foreign_log.id) }
        end

        test "account event queries never return logs from another account" do
            own_log = create_account_log(operation: "account_initialized")
            other_audit = audit_account_for(secondary_core_account)
            foreign_log = other_audit.account_logs.create!(operation: "foreign_account_event")
            service = service_for(core_user, kind: "account")

            logs = service.index

            assert_equal [ own_log.id ], logs.map(&:id)
            assert_raises(ActiveRecord::RecordNotFound) { service.find(foreign_log.id) }
        end

        test "find applies the event type user scope and account scope" do
            own_log = create_user_log(user: core_user, operation: "profile_updated")
            colleague_log = create_user_log(user: same_account_core_user, operation: "role_assigned")
            account_log = create_account_log(operation: "account_initialized")

            user_service = service_for(core_user)
            assert_equal own_log, user_service.find(own_log.id)
            assert_equal colleague_log, user_service.find(colleague_log.id)

            account_service = service_for(core_user, kind: "account")
            assert_equal account_log, account_service.find(account_log.id)
        end

        test "searches sorts and paginates through safe query options" do
            create_user_log(
                user: core_user,
                operation: "ticket_opened",
                source: "TicketsController",
                created_at: 1.minute.ago
            )
            newest = create_user_log(
                user: core_user,
                operation: "ticket_closed",
                source: "TicketsController",
                created_at: Time.current
            )
            create_user_log(user: core_user, operation: "profile_updated", source: "UsersController")

            logs = service_for(
                core_user,
                search: "TICKET",
                pagination: { page: 1, perPage: 1 },
                order: { by: "created_at", dir: "desc" }
            ).index

            assert_equal 2, logs.total_count
            assert_equal 2, logs.total_pages
            assert_equal newest.id, logs.first.id
        end

        test "caps page size ignores unsafe sorting and excludes requests and journals" do
            user_log = create_user_log(user: core_user, operation: "profile_updated")
            audit_account.user_requests.create!(
                user: core_user,
                request_controller: "lesli/users",
                request_action: "update",
                request_count: 1,
                date: Date.current
            )
            audit_account.user_journals.create!(
                user: core_user,
                event_uid: "journal-event",
                request_controller: "lesli/users",
                request_action: "update",
                date: Date.current,
                retain: true
            )

            logs = service_for(
                core_user,
                pagination: { page: 0, perPage: 1_000 },
                order: { by: "account_id; DROP TABLE users", dir: "sideways" }
            ).index

            assert_equal 1, logs.current_page
            assert_equal 100, logs.limit_value
            assert_equal [ user_log.id ], logs.map(&:id)
            assert logs.all? { |log| log.is_a?(LesliAudit::UserLog) }
        end

        private

        def create_user_log(user:, operation:, source: "UsersController", created_at: Time.current)
            audit_account.user_logs.create!(
                user:,
                operation:,
                source:,
                actor_uid: user.uid,
                created_at:
            )
        end

        def create_account_log(operation:)
            audit_account.account_logs.create!(
                user: core_user,
                operation:,
                actor_uid: core_user.uid
            )
        end

        def audit_account_for(account)
            LesliAudit::Account.find_or_create_by!(account:) do |audit|
                audit.name = account.name
            end
        end

        def service_for(user, overrides = {})
            query = {
                search: nil,
                kind: "user",
                pagination: { page: 1, perPage: 12 },
                order: { by: "created_at", dir: "desc" }
            }.deep_merge(overrides)

            LesliAudit::LogService.new(user, query)
        end
    end
end
