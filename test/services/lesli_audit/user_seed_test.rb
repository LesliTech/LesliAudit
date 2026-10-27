require "test_helper"

module LesliAudit
    class UserSeedTest < ActiveSupport::TestCase
        test "demo user seed populates every Users dashboard section and is idempotent" do
            core_account
            seed = LesliAudit::Engine.root.join("db", "seed", "users.rb")

            load seed

            assert_equal 100, demo_users.count
            assert_equal 560, demo_journals.count
            assert demo_users.where(active: false).exists?
            assert demo_users.where.not(locked_at: nil).exists?
            assert demo_users.where(confirmed_at: nil).exists?
            assert demo_users.where(last_sign_in_at: 30.days.ago..).exists?
            assert demo_users.where(failed_attempts: 1..).exists?
            assert demo_users.where.not(deleted_at: nil).exists?

            dashboard = LesliAudit::UserService.new(demo_users.where(deleted_at: nil).first, {}).dashboard
            assert dashboard.fetch(:registrations).any? { |month| month.fetch("yaxiskey").positive? }
            assert_equal 280, dashboard.fetch(:working_hours).length

            load seed

            assert_equal 100, demo_users.count
            assert_equal 560, demo_journals.count
        end

        private

        def demo_users
            Lesli::User.with_deleted.where("uid LIKE ?", "DEV-USR-%")
        end

        def demo_journals
            LesliAudit::UserJournal.where("event_uid LIKE ?", "DEV-USR-ACTIVITY-%")
        end
    end
end
