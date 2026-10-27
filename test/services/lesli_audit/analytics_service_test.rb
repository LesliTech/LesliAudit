require "test_helper"

module LesliAudit
    class AnalyticsServiceTest < ActiveSupport::TestCase
        test "summarizes authenticated application usage" do
            audit_account.account_requests.create!(
                request_controller: "lesli/dashboard",
                request_action: "index",
                request_count: 7,
                date: Date.current
            )
            audit_account.account_requests.create!(
                request_controller: "lesli/users",
                request_action: "index",
                request_count: 3,
                date: Date.current
            )
            audit_account.account_devices.create!(
                agent_platform: "macOS",
                agent_browser: "Safari",
                agent_device: "desktop",
                agent_count: 2,
                date: Date.current
            )

            service = LesliAudit::AnalyticsService.new(core_user, bytime: "month")
            dashboard = service.dashboard

            assert_equal({ controllers: 2, requests: 10 }, dashboard[:summary])
            assert_equal 10, dashboard[:request_trend].first["yaxiskey"].to_i
            assert_equal "lesli/dashboard", dashboard[:top_controllers].first["request_controller"]
            assert_equal "Safari", dashboard[:browsers].first[:browser]
            assert_equal "desktop", dashboard[:devices].first[:device]
            assert_equal "macOS", dashboard[:operating_systems].first[:operating_system]
        end

        test "does not include analytics from another account" do
            audit_account.account_requests.create!(
                request_controller: "lesli/dashboard",
                request_action: "index",
                request_count: 4,
                date: Date.current
            )

            other_audit = LesliAudit::Account.find_or_create_by!(account: secondary_core_account) do |account|
                account.name = secondary_core_account.name
            end
            other_audit.account_requests.create!(
                request_controller: "lesli/admin",
                request_action: "index",
                request_count: 100,
                date: Date.current
            )

            service = LesliAudit::AnalyticsService.new(core_user, bytime: "month")
            dashboard = service.dashboard

            assert_equal({ controllers: 1, requests: 4 }, dashboard[:summary])
            assert_equal ["lesli/dashboard"], dashboard[:top_controllers].pluck("request_controller")
        end

        test "uses an available generic icon for Linux distributions" do
            audit_account.account_devices.create!(
                agent_platform: "Linux",
                agent_browser: "Firefox",
                agent_device: "desktop",
                agent_count: 1,
                date: Date.current
            )

            dashboard = LesliAudit::AnalyticsService.new(core_user, bytime: "month").dashboard
            linux = dashboard[:operating_systems].find do |operating_system|
                operating_system[:operating_system] == "Linux"
            end

            assert_equal "computer-fill", linux[:icon]
        end

        test "does not cache database queries outside production" do
            request = audit_account.account_requests.create!(
                request_controller: "lesli/dashboard",
                request_action: "index",
                request_count: 4,
                date: Date.current
            )
            service = LesliAudit::AnalyticsService.new(core_user, bytime: "month")

            first_dashboard = service.dashboard
            request.update!(request_count: 9)
            second_dashboard = service.dashboard

            assert_not service.send(:cache_enabled?)
            assert_equal 4, first_dashboard[:summary][:requests]
            assert_equal 9, second_dashboard[:summary][:requests]
        end

        test "caches the complete dashboard for one hour" do
            travel_to Time.zone.local(2026, 10, 27, 12) do
                request = audit_account.account_requests.create!(
                    request_controller: "lesli/dashboard",
                    request_action: "index",
                    request_count: 4,
                    date: Date.current
                )
                cache = ActiveSupport::Cache::MemoryStore.new
                service = cached_service(core_user, cache)

                first_dashboard = service.dashboard
                request.update!(request_count: 9)
                cached_dashboard = service.dashboard

                assert_equal 1.hour, LesliAudit::AnalyticsService::CACHE_TTL
                assert_equal 4, first_dashboard[:summary][:requests]
                assert_equal 4, cached_dashboard[:summary][:requests]

                travel 1.hour + 1.second

                refreshed_dashboard = service.dashboard
                assert_equal 9, refreshed_dashboard[:summary][:requests]
            end
        end

        test "isolates cached dashboards by account" do
            audit_account.account_requests.create!(
                request_controller: "lesli/dashboard",
                request_action: "index",
                request_count: 4,
                date: Date.current
            )
            other_audit = LesliAudit::Account.find_or_create_by!(account: secondary_core_account) do |account|
                account.name = secondary_core_account.name
            end
            other_audit.account_requests.create!(
                request_controller: "lesli/admin",
                request_action: "index",
                request_count: 100,
                date: Date.current
            )
            cache = ActiveSupport::Cache::MemoryStore.new

            first_dashboard = cached_service(core_user, cache).dashboard
            second_dashboard = cached_service(secondary_core_user, cache).dashboard

            assert_equal 4, first_dashboard[:summary][:requests]
            assert_equal 100, second_dashboard[:summary][:requests]
        end

        private

        def cached_service(user, cache)
            service = LesliAudit::AnalyticsService.new(user, bytime: "month")
            service.define_singleton_method(:cache_enabled?) { true }
            service.define_singleton_method(:cache_store) { cache }
            service
        end
    end
end
