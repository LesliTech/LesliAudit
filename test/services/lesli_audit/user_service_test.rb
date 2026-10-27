require "test_helper"

module LesliAudit
    class UserServiceTest < ActiveSupport::TestCase
        test "dashboard summarizes account users without analytics or request data" do
            travel_to Time.zone.local(2026, 10, 27, 12, 0, 0) do
                prepare_current_users
                create_user(
                    email: "deleted-user@example.com",
                    deleted_at: Time.current,
                    created_at: 1.month.ago
                )
                secondary_core_user.update_columns(
                    active: false,
                    failed_attempts: 5,
                    locked_until: 1.day.from_now,
                    updated_at: Time.current
                )

                dashboard = service.dashboard

                assert_equal({
                    registered: 3,
                    enabled: 1,
                    active_last_30_days: 1,
                    deactivated: 1,
                    deleted: 1
                }, dashboard.fetch(:summary))
                assert_equal({
                    unconfirmed: 1,
                    never_signed_in: 1,
                    failed_sign_ins: 1,
                    locked: 1
                }, dashboard.fetch(:attention))
                assert_not dashboard.key?(:requests)
                assert_not dashboard.key?(:top_controllers)
            end
        end

        test "registrations contain twelve account-scoped monthly points" do
            travel_to Time.zone.local(2026, 10, 27, 12, 0, 0) do
                core_user.update_columns(created_at: 2.months.ago, updated_at: Time.current)
                same_account_core_user.update_columns(created_at: 1.month.ago, updated_at: Time.current)
                secondary_core_user.update_columns(created_at: 1.month.ago, updated_at: Time.current)

                registrations = service.dashboard.fetch(:registrations)

                assert_equal 12, registrations.length
                assert_equal current_account_user_count, registrations.sum { |month| month.fetch("yaxiskey") }
                assert_equal "2025-11-01", registrations.first.fetch("xaxiskey")
                assert_equal "2026-10-01", registrations.last.fetch("xaxiskey")
            end
        end

        test "working hours use only retained journals from the current account and last thirty days" do
            travel_to Time.zone.local(2026, 10, 27, 18, 0, 0) do
                create_journal(core_user, "first", at: Time.zone.local(2026, 10, 27, 9, 0, 0))
                create_journal(core_user, "last", at: Time.zone.local(2026, 10, 27, 17, 0, 0))
                create_journal(core_user, "transient", at: Time.zone.local(2026, 10, 27, 8, 0, 0), retain: false)
                create_journal(core_user, "expired", at: 31.days.ago)
                create_foreign_journal

                working_hours = service.dashboard.fetch(:working_hours)

                assert_equal 1, working_hours.length
                assert_equal({
                    user_id: core_user.id,
                    user_email: core_user.email,
                    date: Date.new(2026, 10, 27),
                    first_activity: "09:00",
                    last_activity: "17:00"
                }, working_hours.first)
                assert_not working_hours.first.key?(:requests)
            end
        end

        test "working hours return only the twenty most recent records" do
            travel_to Time.zone.local(2026, 10, 27, 18, 0, 0) do
                26.times do |days_ago|
                    create_journal(
                        core_user,
                        "limit-#{days_ago}",
                        at: days_ago.days.ago.change(hour: 9)
                    )
                end

                working_hours = service.dashboard.fetch(:working_hours)

                assert_equal 20, working_hours.length
                assert_equal Date.current, working_hours.first.fetch(:date)
                assert_equal 19.days.ago.to_date, working_hours.last.fetch(:date)
                assert_not_includes working_hours.pluck(:date), 20.days.ago.to_date
            end
        end

        private

        def service
            audit_account
            LesliAudit::UserService.new(core_user, {})
        end

        def prepare_current_users
            core_user.update_columns(
                active: true,
                confirmed_at: Time.current,
                last_sign_in_at: 1.day.ago,
                failed_attempts: 0,
                locked_at: nil,
                locked_until: nil,
                deleted_at: nil,
                updated_at: Time.current
            )
            same_account_core_user.update_columns(
                active: false,
                confirmed_at: nil,
                last_sign_in_at: nil,
                failed_attempts: 2,
                locked_at: nil,
                locked_until: 1.day.from_now,
                deleted_at: nil,
                updated_at: Time.current
            )
        end

        def create_user(email:, created_at:, deleted_at: nil)
            Lesli::User.unscoped.insert_all!([ {
                account_id: core_account.id,
                uid: email,
                first_name: "Report",
                last_name: "User",
                email:,
                active: true,
                encrypted_password: "",
                sign_in_count: 0,
                failed_attempts: 0,
                deleted_at:,
                created_at:,
                updated_at: Time.current
            } ])
        end

        def current_account_user_count
            core_account.users.with_deleted
                .where(created_at: 11.months.ago.beginning_of_month..)
                .count
        end

        def create_journal(user, uid, at:, retain: true)
            audit_account.user_journals.create!(
                user:,
                event_uid: "users-dashboard-#{uid}",
                request_controller: ("lesli/users" if retain),
                request_action: ("index" if retain),
                date: at.to_date,
                retain:,
                created_at: at
            )
        end

        def create_foreign_journal
            foreign_audit = LesliAudit::Account.find_or_create_by!(account: secondary_core_account) do |account|
                account.name = secondary_core_account.name
            end
            foreign_audit.user_journals.create!(
                user: secondary_core_user,
                event_uid: "foreign-users-dashboard",
                request_controller: "lesli/users",
                request_action: "index",
                date: Date.current,
                retain: true,
                created_at: Time.current
            )
        end
    end
end
