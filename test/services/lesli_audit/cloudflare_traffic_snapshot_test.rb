require "test_helper"

module LesliAudit
    class CloudflareTrafficSnapshotTest < ActiveSupport::TestCase
        test "normalizes Cloudflare dimensions and removes sensitive URL data" do
            snapshot = build_snapshot(
                hostname: "https://WWW.Example.COM.:443/account?token=secret",
                path: "https://example.com/demo//cafe/?token=secret#private",
                breakdowns: [
                    breakdown("country", " gt "),
                    breakdown("device", "Smartphone"),
                    breakdown("browser", " Mobile Safari "),
                    breakdown("referrer", "https://user:password@News.Example.com/article?token=secret")
                ]
            )

            assert_equal "www.example.com", snapshot.hostname
            assert_equal "/demo/cafe", snapshot.path
            assert_equal [ "GT", "mobile", "mobile safari", "news.example.com" ],
                snapshot.breakdowns.pluck(:value)
            refute_includes snapshot.inspect, "token"
            refute_includes snapshot.inspect, "password"
        end

        test "distinguishes an omitted breakdown from an explicitly empty one" do
            omitted = build_snapshot
            empty = build_snapshot(breakdowns: [])

            assert_not omitted.breakdowns_provided?
            assert_equal [], omitted.breakdowns
            assert empty.breakdowns_provided?
            assert_equal [], empty.breakdowns
        end

        test "rejects duplicate breakdowns after normalization" do
            error = assert_raises(ArgumentError) do
                build_snapshot(
                    breakdowns: [
                        breakdown("country", "gt"),
                        breakdown("country", " GT ")
                    ]
                )
            end

            assert_equal "breakdowns must be unique after normalization", error.message
        end

        test "rejects negative totals before import" do
            error = assert_raises(ArgumentError) do
                build_snapshot(page_views: -1)
            end

            assert_equal "page_views must be a nonnegative integer", error.message
        end

        private

        def build_snapshot(hostname: "example.com", path: "/demo", page_views: 100,
            visits: 70, breakdowns: described_omission)
            arguments = {
                hostname:,
                path:,
                resource_type: "Profile",
                resource_id: 27,
                date: Date.new(2026, 10, 26),
                page_views:,
                visits:,
                snapshot_at: Time.zone.local(2026, 10, 26, 22)
            }
            arguments[:breakdowns] = breakdowns unless breakdowns.equal?(described_omission)
            LesliAudit::CloudflareTrafficSnapshot.new(**arguments)
        end

        def breakdown(dimension, value)
            { dimension:, value:, page_views: 10, visits: 7 }
        end

        def described_omission
            LesliAudit::CloudflareTrafficSnapshot::BREAKDOWNS_OMITTED
        end
    end
end
