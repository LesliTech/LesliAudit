require "test_helper"

module LesliAudit
    class VisitorRollupImporterTest < ActiveSupport::TestCase
        test "imports a complete daily provider snapshot" do
            synced_at = Time.zone.local(2026, 10, 26, 22)

            rollup = import_snapshot(
                page_views: 184,
                visits: 126,
                synced_at:,
                breakdowns: [
                    { dimension: "country", value: "GT", page_views: 112, visits: 79 },
                    { dimension: "device", value: "mobile", page_views: 126, visits: 88 }
                ]
            )

            assert_equal audit_account, rollup.account
            assert_equal "Profile", rollup.resource_type
            assert_equal 27, rollup.resource_id
            assert_equal Date.new(2026, 10, 26), rollup.date
            assert_equal 184, rollup.page_views
            assert_equal 126, rollup.visits
            assert_equal synced_at, rollup.synced_at
            assert_equal 2, rollup.visitor_breakdowns.count
        end

        test "reimport replaces counts and removes stale breakdowns" do
            first = import_snapshot(
                page_views: 100,
                visits: 70,
                breakdowns: [
                    { dimension: "country", value: "GT", page_views: 80, visits: 55 },
                    { dimension: "country", value: "US", page_views: 20, visits: 15 }
                ]
            )

            second = import_snapshot(
                page_views: 120,
                visits: 82,
                breakdowns: [
                    { dimension: "country", value: "GT", page_views: 99, visits: 68 }
                ]
            )

            assert_equal first.id, second.id
            assert_equal 1, LesliAudit::VisitorRollup.count
            assert_equal 120, second.reload.page_views
            assert_equal 82, second.visits
            assert_equal ["GT"], second.visitor_breakdowns.pluck(:value)
            assert_equal 99, second.visitor_breakdowns.first.page_views
        end

        test "refuses to reattribute an existing daily provider key" do
            import_snapshot(page_views: 10, visits: 7)

            assert_raises(LesliAudit::VisitorRollupImporter::ResourceConflict) do
                import_snapshot(resource_id: 28, page_views: 10, visits: 7)
            end

            assert_equal 27, LesliAudit::VisitorRollup.first.resource_id
        end

        test "rejects duplicate and negative provider data before writing" do
            assert_raises(ArgumentError) do
                import_snapshot(
                    page_views: 2,
                    visits: 1,
                    breakdowns: [
                        { dimension: "country", value: "GT", page_views: 1, visits: 1 },
                        { dimension: "country", value: "GT", page_views: 1, visits: 0 }
                    ]
                )
            end

            assert_raises(ArgumentError) do
                import_snapshot(page_views: -1, visits: 0)
            end

            assert_equal 0, LesliAudit::VisitorRollup.count
        end

        private

        def import_snapshot(resource_id: 27, page_views:, visits:, breakdowns: [], synced_at: Time.current)
            LesliAudit::VisitorRollupImporter.call(
                account: audit_account,
                provider: "cloudflare",
                provider_key: "/ldonis",
                resource_type: "Profile",
                resource_id:,
                date: Date.new(2026, 10, 26),
                page_views:,
                visits:,
                breakdowns:,
                synced_at:
            )
        end
    end
end
