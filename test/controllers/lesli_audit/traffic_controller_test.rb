require "test_helper"

module LesliAudit
    class TrafficControllerTest < ActiveSupport::TestCase
        test "assigns provider traffic for the current account" do
            snapshot = LesliAudit::CloudflareTrafficSnapshot.new(
                hostname: "example.com",
                path: "/demo",
                resource_type: "Profile",
                resource_id: 27,
                date: Date.current,
                page_views: 10,
                visits: 7,
                snapshot_at: Time.current,
                breakdowns: [
                    { dimension: "country", value: "GT", page_views: 10, visits: 7 }
                ]
            )
            LesliAudit::TrafficSnapshotImporter.call(
                account: audit_account,
                snapshot:
            )

            user = core_user
            controller = LesliAudit::TrafficController.new
            controller.define_singleton_method(:current_user) { user }
            controller.define_singleton_method(:traffic_query) { { bytime: "month" } }

            controller.index

            assert_equal 10, controller.instance_variable_get(:@summary).fetch(:page_views)
            assert_equal 10, controller.instance_variable_get(:@trend).first.fetch(:page_views)
            assert_equal "/demo", controller.instance_variable_get(:@paths).first.fetch("path")
            assert_equal "Profile #27", controller.instance_variable_get(:@resources).first.fetch("resource")
            assert_equal "GT", controller.instance_variable_get(:@countries).first.fetch(:value)
            assert_equal "Cloudflare", controller.instance_variable_get(:@synchronization).fetch(:source)
        end

        test "inherits authentication and role authorization from the Lesli controller" do
            assert_equal LesliAudit::ApplicationController, LesliAudit::TrafficController.superclass
            assert_equal Lesli::ApplicationLesliController, LesliAudit::ApplicationController.superclass
        end
    end
end
