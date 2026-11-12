require "test_helper"

module LesliAudit
    class TrafficSnapshotImporterTest < ActiveSupport::TestCase
        test "imports a complete daily Cloudflare snapshot" do
            snapshot_at = Time.zone.local(2026, 10, 26, 22)
            snapshot = build_snapshot(
                page_views: 184,
                visits: 126,
                snapshot_at:,
                breakdowns: [
                    breakdown("country", "GT", 112, 79),
                    breakdown("device", "mobile", 126, 88)
                ]
            )

            rollup = import(snapshot)

            assert_equal audit_account, rollup.account
            assert_equal "cloudflare", rollup.provider
            assert_equal "example.com", rollup.hostname
            assert_equal "/ldonis", rollup.path
            assert_equal "Profile", rollup.resource_type
            assert_equal 27, rollup.resource_id
            assert_equal Date.new(2026, 10, 26), rollup.date
            assert_equal 184, rollup.page_views
            assert_equal 126, rollup.visits
            assert_equal snapshot_at, rollup.snapshot_at
            assert_equal 2, rollup.traffic_breakdowns.count
        end

        test "retrying the same snapshot is idempotent" do
            snapshot = build_snapshot(
                breakdowns: [ breakdown("country", "GT", 100, 70) ]
            )

            first = import(snapshot)
            breakdown_ids = first.traffic_breakdowns.ids
            second = import(snapshot)

            assert_equal first.id, second.id
            assert_equal 1, LesliAudit::TrafficRollup.count
            assert_equal breakdown_ids, second.traffic_breakdowns.ids
        end

        test "omitted breakdowns are preserved and an empty set clears them" do
            initial = build_snapshot(
                snapshot_at: timestamp(10),
                breakdowns: [
                    breakdown("country", "GT", 80, 55),
                    breakdown("country", "US", 20, 15)
                ]
            )
            import(initial)

            without_breakdowns = build_snapshot(
                page_views: 120,
                visits: 82,
                snapshot_at: timestamp(11)
            )
            preserved = import(without_breakdowns)

            assert_equal 2, preserved.traffic_breakdowns.count
            assert_equal 120, preserved.page_views

            empty_breakdowns = build_snapshot(
                page_views: 130,
                visits: 90,
                snapshot_at: timestamp(12),
                breakdowns: []
            )
            cleared = import(empty_breakdowns)

            assert_equal 0, cleared.traffic_breakdowns.count
            assert_equal 130, cleared.page_views
        end

        test "an older snapshot cannot replace newer totals or breakdowns" do
            newer = build_snapshot(
                page_views: 200,
                visits: 140,
                snapshot_at: timestamp(12),
                breakdowns: [ breakdown("country", "GT", 200, 140) ]
            )
            import(newer)

            older = build_snapshot(
                page_views: 10,
                visits: 7,
                snapshot_at: timestamp(11),
                breakdowns: []
            )
            rollup = import(older)

            assert_equal 200, rollup.page_views
            assert_equal 140, rollup.visits
            assert_equal timestamp(12), rollup.snapshot_at
            assert_equal [ "GT" ], rollup.traffic_breakdowns.pluck(:value)
        end

        test "refuses to reattribute an existing daily provider path" do
            import(build_snapshot)

            error = assert_raises(LesliAudit::TrafficSnapshotImporter::ResourceConflict) do
                import(build_snapshot(resource_id: 28, snapshot_at: timestamp(11)))
            end

            assert_match "another resource", error.message
            assert_equal 27, LesliAudit::TrafficRollup.first.resource_id
        end

        test "rolls back totals when replacing breakdowns fails" do
            import(
                build_snapshot(
                    page_views: 100,
                    visits: 70,
                    snapshot_at: timestamp(10),
                    breakdowns: [ breakdown("country", "GT", 100, 70) ]
                )
            )
            replacement = build_snapshot(
                page_views: 200,
                visits: 140,
                snapshot_at: timestamp(11),
                breakdowns: [ breakdown("country", "US", 200, 140) ]
            )
            assert_raises(ActiveRecord::StatementInvalid) do
                with_breakdown_upsert_failure do
                    import(replacement)
                end
            end

            rollup = LesliAudit::TrafficRollup.first
            assert_equal 100, rollup.page_views
            assert_equal timestamp(10), rollup.snapshot_at
            assert_equal [ "GT" ], rollup.traffic_breakdowns.pluck(:value)
        end

        private

        def import(snapshot)
            LesliAudit::TrafficSnapshotImporter.call(account: audit_account, snapshot:)
        end

        def build_snapshot(resource_id: 27, page_views: 100, visits: 70,
            snapshot_at: timestamp(10), breakdowns: described_omission)
            arguments = {
                hostname: "example.com",
                path: "/ldonis",
                resource_type: "Profile",
                resource_id:,
                date: Date.new(2026, 10, 26),
                page_views:,
                visits:,
                snapshot_at:
            }
            arguments[:breakdowns] = breakdowns unless breakdowns.equal?(described_omission)
            LesliAudit::CloudflareTrafficSnapshot.new(**arguments)
        end

        def breakdown(dimension, value, page_views, visits)
            { dimension:, value:, page_views:, visits: }
        end

        def timestamp(hour)
            Time.zone.local(2026, 10, 26, hour)
        end

        def described_omission
            LesliAudit::CloudflareTrafficSnapshot::BREAKDOWNS_OMITTED
        end

        def with_breakdown_upsert_failure
            original = LesliAudit::TrafficBreakdown.method(:upsert_all)
            LesliAudit::TrafficBreakdown.define_singleton_method(:upsert_all) do |*, **|
                raise ActiveRecord::StatementInvalid, "provider failure"
            end
            yield
        ensure
            LesliAudit::TrafficBreakdown.define_singleton_method(:upsert_all, original)
        end
    end

    class TrafficSnapshotImporterConcurrencyTest < ActiveSupport::TestCase
        self.use_transactional_tests = false

        setup do
            LesliAudit::TrafficBreakdown.delete_all
            LesliAudit::TrafficRollup.delete_all
            audit_account
        end

        teardown do
            LesliAudit::TrafficBreakdown.delete_all
            LesliAudit::TrafficRollup.delete_all
        end

        test "concurrent imports keep the newest complete snapshot" do
            older = build_snapshot(page_views: 100, visits: 70, hour: 10)
            newer = build_snapshot(page_views: 200, visits: 140, hour: 11)
            ready = Queue.new
            start = Queue.new

            threads = [ older, newer ].map do |snapshot|
                Thread.new do
                    ActiveRecord::Base.connection_pool.with_connection do
                        ready << true
                        start.pop
                        LesliAudit::TrafficSnapshotImporter.call(account: audit_account, snapshot:)
                    end
                end
            end
            threads.length.times { ready.pop }
            threads.length.times { start << true }
            threads.each(&:value)

            rollup = LesliAudit::TrafficRollup.find_by!(path: "/concurrent")
            assert_equal 1, LesliAudit::TrafficRollup.where(path: "/concurrent").count
            assert_equal 200, rollup.page_views
            assert_equal 140, rollup.visits
            assert_equal Time.zone.local(2026, 10, 26, 11), rollup.snapshot_at
            assert_equal [ "US" ], rollup.traffic_breakdowns.pluck(:value)
        end

        private

        def build_snapshot(page_views:, visits:, hour:)
            LesliAudit::CloudflareTrafficSnapshot.new(
                hostname: "example.com",
                path: "/concurrent",
                resource_type: "Profile",
                resource_id: 27,
                date: Date.new(2026, 10, 26),
                page_views:,
                visits:,
                snapshot_at: Time.zone.local(2026, 10, 26, hour),
                breakdowns: [ {
                    dimension: "country",
                    value: hour == 11 ? "US" : "GT",
                    page_views:,
                    visits:
                } ]
            )
        end
    end
end
