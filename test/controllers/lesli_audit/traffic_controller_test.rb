require "test_helper"

module LesliAudit
    class TrafficControllerTest < ActiveSupport::TestCase
        test "assigns provider traffic for the current account" do
            LesliAudit::TrafficRollupImporter.call(
                account: audit_account,
                provider: "cloudflare",
                provider_key: "/demo",
                resource_type: "Profile",
                resource_id: 27,
                date: Date.current,
                page_views: 10,
                visits: 7,
                breakdowns: [
                    { dimension: "country", value: "GT", page_views: 10, visits: 7 }
                ]
            )

            user = core_user
            controller = LesliAudit::TrafficController.new
            controller.define_singleton_method(:current_user) { user }
            controller.define_singleton_method(:traffic_query) { { bytime: "month" } }

            controller.index

            assert_equal 10, controller.instance_variable_get(:@summary).fetch(:page_views)
            assert_equal 10, controller.instance_variable_get(:@traffic).first.fetch("yaxiskey")
            assert_equal "/demo", controller.instance_variable_get(:@paths).first.fetch("path")
            assert_equal "Profile #27", controller.instance_variable_get(:@resources).first.fetch("resource")
            assert_equal "GT", controller.instance_variable_get(:@countries).first.fetch(:value)
        end
    end
end
