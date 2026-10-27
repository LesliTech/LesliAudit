require "test_helper"

module LesliAudit
    class TrafficServiceTest < ActiveSupport::TestCase
        test "summarizes and groups provider traffic for the current account" do
            import_snapshot(
                resource_id: 27,
                provider_key: "/ldonis",
                date: Date.current,
                page_views: 100,
                visits: 70,
                breakdowns: [
                    { dimension: "country", value: "GT", page_views: 80, visits: 55 },
                    { dimension: "country", value: "US", page_views: 20, visits: 15 }
                ]
            )
            import_snapshot(
                resource_id: 28,
                provider_key: "/demo",
                date: Date.current,
                page_views: 40,
                visits: 25
            )

            service = LesliAudit::TrafficService.new(core_user, bytime: "all")

            assert_equal({ page_views: 140, visits: 95, resources: 2, sources: 2 }, service.summary)
            assert_equal 140, service.traffic.first["yaxiskey"]
            assert_equal "/ldonis", service.paths.first["path"]
            assert_equal 70, service.paths.first["visits"]
            assert_equal 2, service.resources.length
            assert_equal "GT", service.breakdown(:country).first[:value]
            assert_equal 80, service.breakdown(:country).first[:page_views]
        end

        test "returns the ten paths with the most visits" do
            (1..11).each do |number|
                import_snapshot(
                    resource_id: number,
                    provider_key: "/demo/#{number}",
                    date: Date.current,
                    page_views: number + 10,
                    visits: number
                )
            end
            import_snapshot(
                resource_id: 11,
                provider_key: "/demo/11",
                date: Date.yesterday,
                page_views: 20,
                visits: 20
            )

            paths = LesliAudit::TrafficService.new(core_user, bytime: "all").paths

            assert_equal 10, paths.length
            assert_equal "/demo/11", paths.first["path"]
            assert_equal 31, paths.first["visits"]
            assert_not_includes paths.pluck("path"), "/demo/1"
        end

        test "defaults to thirty days and supports a generic resource filter" do
            import_snapshot(
                resource_id: 27,
                provider_key: "/ldonis",
                date: Date.current,
                page_views: 10,
                visits: 7
            )
            import_snapshot(
                resource_id: 28,
                provider_key: "/demo",
                date: Date.current,
                page_views: 5,
                visits: 4
            )
            import_snapshot(
                resource_id: 27,
                provider_key: "/ldonis",
                date: 60.days.ago.to_date,
                page_views: 99,
                visits: 80
            )

            service = LesliAudit::TrafficService.new(
                core_user,
                resource_type: "Profile",
                resource_id: "27"
            )

            assert_equal 10, service.summary[:page_views]
            assert_equal 7, service.summary[:visits]
            assert_equal 1, service.summary[:resources]
        end

        test "does not expose another account traffic" do
            import_snapshot(
                resource_id: 27,
                provider_key: "/ldonis",
                date: Date.current,
                page_views: 10,
                visits: 7
            )

            other_audit = LesliAudit::Account.find_or_create_by!(account: secondary_core_account) do |account|
                account.name = secondary_core_account.name
            end
            LesliAudit::TrafficRollupImporter.call(
                account: other_audit,
                provider: "cloudflare",
                provider_key: "/other",
                resource_type: "Profile",
                resource_id: 91,
                date: Date.current,
                page_views: 500,
                visits: 400
            )

            service = LesliAudit::TrafficService.new(core_user, bytime: "all")

            assert_equal 10, service.summary[:page_views]
            assert_equal 7, service.summary[:visits]
        end

        private

        def import_snapshot(resource_id:, provider_key:, date:, page_views:, visits:, breakdowns: [])
            LesliAudit::TrafficRollupImporter.call(
                account: audit_account,
                provider: "cloudflare",
                provider_key:,
                resource_type: "Profile",
                resource_id:,
                date:,
                page_views:,
                visits:,
                breakdowns:
            )
        end
    end
end
