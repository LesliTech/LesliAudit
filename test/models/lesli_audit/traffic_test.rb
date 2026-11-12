require "test_helper"

module LesliAudit
    class TrafficTest < ActiveSupport::TestCase
        test "rollup maps a hostname and path to an engine-independent resource" do
            rollup = audit_account.traffic_rollups.create!(
                provider: " Cloudflare ",
                hostname: " EXAMPLE.COM ",
                path: " /ldonis ",
                resource_type: " Profile ",
                resource_id: 27,
                date: Date.new(2026, 10, 26),
                page_views: 184,
                visits: 126,
                snapshot_at: Time.current
            )

            assert_equal "cloudflare", rollup.provider
            assert_equal "example.com", rollup.hostname
            assert_equal "/ldonis", rollup.path
            assert_equal "Profile", rollup.resource_type
            assert_equal 27, rollup.resource_id
        end

        test "a provider path has one snapshot per account and day" do
            attributes = {
                provider: "cloudflare",
                hostname: "example.com",
                path: "/ldonis",
                resource_type: "Profile",
                resource_id: 27,
                date: Date.new(2026, 10, 26),
                page_views: 10,
                visits: 7,
                snapshot_at: Time.current
            }
            audit_account.traffic_rollups.create!(attributes)

            duplicate = audit_account.traffic_rollups.new(attributes)

            assert_not duplicate.valid?
            assert_includes duplicate.errors[:path], "has already been taken"
        end

        test "the same path can be tracked on different hostnames" do
            create_rollup
            second_host = create_rollup(hostname: "store.example.com")

            assert_predicate second_host, :persisted?
            assert_equal 2, audit_account.traffic_rollups.where(path: "/ldonis").count
        end

        test "the resource index can preserve multiple historical paths" do
            old_path = create_rollup(path: "/ldonis", date: Date.new(2026, 10, 25))
            new_path = create_rollup(path: "/luisdonis", date: Date.new(2026, 10, 26))

            history = audit_account.traffic_rollups.where(
                resource_type: "Profile",
                resource_id: 27
            ).order(:date)

            assert_equal [ old_path, new_path ], history.to_a
        end

        test "breakdown accepts only normalized supported dimensions" do
            rollup = create_rollup
            breakdown = audit_account.traffic_breakdowns.new(
                traffic_rollup: rollup,
                dimension: " Campaign ",
                value: "launch",
                page_views: 2,
                visits: 1
            )

            assert_not breakdown.valid?
            assert_includes breakdown.errors[:dimension], "is not included in the list"
        end

        test "breakdown must belong to a rollup in the same account" do
            rollup = create_rollup
            other_account = LesliAudit::Account.find_or_create_by!(account: secondary_core_account) do |account|
                account.name = secondary_core_account.name
            end
            breakdown = other_account.traffic_breakdowns.new(
                traffic_rollup: rollup,
                dimension: "country",
                value: "GT",
                page_views: 2,
                visits: 1
            )

            assert_not breakdown.valid?
            assert_includes breakdown.errors[:traffic_rollup], "must belong to the same account"
        end

        private

        def create_rollup(hostname: "example.com", path: "/ldonis", date: Date.new(2026, 10, 26))
            audit_account.traffic_rollups.create!(
                provider: "cloudflare",
                hostname:,
                path:,
                resource_type: "Profile",
                resource_id: 27,
                date:,
                page_views: 2,
                visits: 1,
                snapshot_at: Time.current
            )
        end
    end
end
