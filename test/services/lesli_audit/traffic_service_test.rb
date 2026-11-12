require "test_helper"

module LesliAudit
    class TrafficServiceTest < ActiveSupport::TestCase
        test "summarizes and groups provider traffic for the current account" do
            import_snapshot(
                resource_id: 27,
                path: "/ldonis",
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
                path: "/demo",
                date: Date.current,
                page_views: 40,
                visits: 25
            )

            service = LesliAudit::TrafficService.new(core_user, bytime: "all")

            assert_equal({ page_views: 140, visits: 95, resources: 2, tracked_paths: 2 }, service.summary)
            assert_equal 140, service.trend.first[:page_views]
            assert_equal 95, service.trend.first[:visits]
            assert_equal "example.com", service.paths.first["hostname"]
            assert_equal "/ldonis", service.paths.first["path"]
            assert_equal "Cloudflare", service.paths.first["provider"]
            assert_equal 100, service.paths.first["page_views"]
            assert_equal 70, service.paths.first["visits"]
            assert_equal 2, service.resources.length
            assert_equal "GT", service.breakdown(:country).first[:value]
            assert_equal 80, service.breakdown(:country).first[:page_views]
        end

        test "returns the ten paths with the most visits" do
            (1..11).each do |number|
                import_snapshot(
                    resource_id: number,
                    path: "/demo/#{number}",
                    date: Date.current,
                    page_views: number + 10,
                    visits: number
                )
            end
            import_snapshot(
                resource_id: 11,
                path: "/demo/11",
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
                path: "/ldonis",
                date: Date.current,
                page_views: 10,
                visits: 7
            )
            import_snapshot(
                resource_id: 28,
                path: "/demo",
                date: Date.current,
                page_views: 5,
                visits: 4
            )
            import_snapshot(
                resource_id: 27,
                path: "/ldonis",
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
                path: "/ldonis",
                date: Date.current,
                page_views: 10,
                visits: 7
            )

            other_audit = LesliAudit::Account.find_or_create_by!(account: secondary_core_account) do |account|
                account.name = secondary_core_account.name
            end
            snapshot = LesliAudit::CloudflareTrafficSnapshot.new(
                hostname: "other.example.com",
                path: "/other",
                resource_type: "Profile",
                resource_id: 91,
                date: Date.current,
                page_views: 500,
                visits: 400,
                snapshot_at: Time.current
            )
            LesliAudit::TrafficSnapshotImporter.call(
                account: other_audit,
                snapshot:
            )

            service = LesliAudit::TrafficService.new(core_user, bytime: "all")

            assert_equal 10, service.summary[:page_views]
            assert_equal 7, service.summary[:visits]
        end

        test "calculates top ten percentages from the complete breakdown" do
            breakdowns = (1..12).map do |number|
                count = 13 - number
                {
                    dimension: "country",
                    value: format("A%X", number - 1),
                    page_views: count,
                    visits: count
                }
            end
            import_snapshot(
                resource_id: 27,
                path: "/ldonis",
                date: Date.current,
                page_views: 78,
                visits: 78,
                breakdowns:
            )

            countries = LesliAudit::TrafficService.new(core_user, bytime: "all").breakdown(:country)

            assert_equal 11, countries.length
            assert_equal 15.4, countries.first[:percentage]
            assert_equal 3, countries.last[:page_views]
            assert_equal 3.8, countries.last[:percentage]
            assert countries.last[:other]
        end

        test "reports the provider and whether synchronization is stale" do
            snapshot_at = Time.zone.local(2026, 10, 29, 10)
            import_snapshot(
                resource_id: 27,
                path: "/ldonis",
                date: snapshot_at.to_date,
                page_views: 10,
                visits: 7,
                snapshot_at:
            )

            service = LesliAudit::TrafficService.new(core_user, bytime: "all")
            fresh = service.synchronization(current_time: snapshot_at + 12.hours)
            stale = service.synchronization(current_time: snapshot_at + 37.hours)

            assert_equal "Cloudflare", fresh[:source]
            assert_equal snapshot_at, fresh[:last_synced_at]
            assert_not fresh[:stale]
            assert stale[:stale]
        end

        test "uses the latest successful Cloudflare synchronization" do
            snapshot_at = 3.days.ago
            import_snapshot(
                resource_id: 27,
                path: "/ldonis",
                date: snapshot_at.to_date,
                page_views: 10,
                visits: 7,
                snapshot_at:
            )
            synchronized_at = 2.hours.ago
            LesliAudit::CloudflareTrafficSync.create!(
                account: audit_account,
                zone_id: "zone-123",
                period_start: Date.yesterday,
                period_end: Date.yesterday,
                status: :succeeded,
                last_synced_at: synchronized_at
            )

            status = LesliAudit::TrafficService.new(core_user).synchronization

            assert_equal "Cloudflare", status[:source]
            assert_equal synchronized_at, status[:last_synced_at]
            assert_not status[:stale]
        end

        private

        def import_snapshot(resource_id:, path:, date:, page_views:, visits:, breakdowns: [], snapshot_at: date.in_time_zone)
            snapshot = LesliAudit::CloudflareTrafficSnapshot.new(
                hostname: "example.com",
                path:,
                resource_type: "Profile",
                resource_id:,
                date:,
                page_views:,
                visits:,
                snapshot_at:,
                breakdowns:
            )
            LesliAudit::TrafficSnapshotImporter.call(
                account: audit_account,
                snapshot:
            )
        end

    end
end
