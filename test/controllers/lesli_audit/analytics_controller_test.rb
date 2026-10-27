require "test_helper"

module LesliAudit
    class AnalyticsControllerTest < ActiveSupport::TestCase
        test "assigns authenticated analytics" do
            audit_account.account_requests.create!(
                request_controller: "lesli/dashboard",
                request_action: "index",
                request_count: 10,
                date: Date.current
            )
            audit_account.account_devices.create!(
                agent_platform: "macOS",
                agent_browser: "Safari",
                agent_device: "desktop",
                agent_count: 2,
                date: Date.current
            )

            user = core_user
            controller = LesliAudit::AnalyticsController.new
            controller.define_singleton_method(:current_user) { user }
            controller.define_singleton_method(:query) { { bytime: "month" } }

            controller.index

            assert_equal({ controllers: 1, requests: 10 }, controller.instance_variable_get(:@summary))
            assert_equal 10, controller.instance_variable_get(:@request_trend).first["yaxiskey"]
            assert_equal "lesli/dashboard", controller.instance_variable_get(:@top_controllers).first["request_controller"]
            assert_equal "Safari", controller.instance_variable_get(:@browsers).first[:browser]
            assert_equal "desktop", controller.instance_variable_get(:@devices).first[:device]
            assert_equal "macOS", controller.instance_variable_get(:@operating_systems).first[:operating_system]
        end
    end
end
