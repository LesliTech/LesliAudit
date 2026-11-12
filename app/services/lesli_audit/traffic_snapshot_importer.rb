module LesliAudit
    # Persists one complete set of totals for a Cloudflare path and day.
    # A newer snapshot replaces the totals; retries and older snapshots are
    # no-ops. Breakdowns are replaced only when the DTO explicitly provides
    # them, allowing omitted data and an intentionally empty set to differ.
    class TrafficSnapshotImporter
        UNIQUE_INDEX = "index_lesli_audit_traffic_rollups_on_provider_path_and_date"
        BREAKDOWN_INDEX = "index_lesli_audit_traffic_breakdowns_on_dimension"

        class ResourceConflict < StandardError; end

        def self.call(account:, snapshot:)
            new(account:, snapshot:).call
        end

        def initialize(account:, snapshot:)
            @account = account
            @snapshot = snapshot
        end

        def call
            validate_input!

            # The account row is the stable lock shared by new and existing
            # paths, so concurrent imports cannot race before a rollup exists.
            account.with_lock do
                rollup = locked_rollup
                ensure_resource_matches!(rollup) if rollup
                return rollup if rollup && rollup.snapshot_at >= snapshot.snapshot_at

                upsert_rollup
                rollup = locked_rollup
                replace_breakdowns(rollup) if snapshot.breakdowns_provided?
                rollup.reload
            end
        end

        private

        attr_reader :account, :snapshot

        def validate_input!
            unless account.is_a?(LesliAudit::Account) && account.persisted?
                raise ArgumentError, "account must be a persisted LesliAudit::Account"
            end
            return if snapshot.is_a?(LesliAudit::CloudflareTrafficSnapshot)

            raise ArgumentError, "snapshot must be a CloudflareTrafficSnapshot"
        end

        def identity
            {
                provider: snapshot.provider,
                hostname: snapshot.hostname,
                path: snapshot.path,
                date: snapshot.date
            }
        end

        def locked_rollup
            account.traffic_rollups.lock.find_by(identity)
        end

        def upsert_rollup
            now = Time.current
            TrafficRollup.upsert_all(
                [ {
                    account_id: account.id,
                    **identity,
                    resource_type: snapshot.resource_type,
                    resource_id: snapshot.resource_id,
                    page_views: snapshot.page_views,
                    visits: snapshot.visits,
                    snapshot_at: snapshot.snapshot_at,
                    created_at: now,
                    updated_at: now
                } ],
                unique_by: UNIQUE_INDEX,
                update_only: %i[page_views visits snapshot_at updated_at]
            )
        end

        def ensure_resource_matches!(rollup)
            return if rollup.resource_type == snapshot.resource_type && rollup.resource_id == snapshot.resource_id

            raise ResourceConflict,
                "hostname and path are already attributed to another resource for this date"
        end

        def replace_breakdowns(rollup)
            relation = rollup.traffic_breakdowns
            relation.delete_all if snapshot.breakdowns.empty?
            return if snapshot.breakdowns.empty?

            now = Time.current
            rows = snapshot.breakdowns.map do |breakdown|
                {
                    account_id: account.id,
                    traffic_rollup_id: rollup.id,
                    **breakdown,
                    created_at: now,
                    updated_at: now
                }
            end
            TrafficBreakdown.upsert_all(
                rows,
                unique_by: BREAKDOWN_INDEX,
                update_only: %i[page_views visits updated_at]
            )

            kept_ids = snapshot.breakdowns.map do |breakdown|
                relation.find_by!(
                    dimension: breakdown[:dimension],
                    value: breakdown[:value]
                ).id
            end
            relation.where.not(id: kept_ids).delete_all
        end
    end
end
