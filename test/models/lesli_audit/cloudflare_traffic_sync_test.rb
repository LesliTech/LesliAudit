require "test_helper"

module LesliAudit
class CloudflareTrafficSyncTest < ActiveSupport::TestCase
  test "allows only one active worker for an account, zone, and period" do
    sync = build_sync
    started_at = Time.zone.local(2026, 10, 29, 2)

    first_execution = sync.acquire!(at: started_at)
    assert first_execution
    assert_nil sync.acquire!(at: started_at + 30.minutes)

    second_execution = sync.acquire!(at: started_at + 3.hours)
    assert second_execution
    assert_not_equal first_execution, second_execution

    assert_not sync.complete!(
      execution_id: first_execution,
      snapshots_count: 99,
      at: started_at + 4.hours
    )
    assert sync.running?
  end

  test "records success, failure, and the last successful synchronization" do
    sync = build_sync
    execution_id = sync.acquire!
    completed_at = Time.zone.local(2026, 10, 29, 3)
    sync.complete!(execution_id:, snapshots_count: 12, at: completed_at)

    assert sync.succeeded?
    assert_equal 12, sync.snapshots_count
    assert_equal completed_at, sync.last_synced_at

    execution_id = sync.acquire!(at: completed_at + 1.hour)
    sync.fail!(
      execution_id:,
      error: RuntimeError.new("provider failed"),
      at: completed_at + 2.hours
    )

    assert sync.failed?
    assert_equal "provider failed", sync.error_message
    assert_equal completed_at, sync.last_synced_at
  end

  test "exposes the latest successful synchronization to traffic reports" do
    account = create_cloudflare_test_account.audit
    older_sync = build_sync(account:)
    latest_sync = build_sync(
      account:,
      period_start: Date.new(2026, 10, 29),
      period_end: Date.new(2026, 10, 29)
    )
    older_time = Time.zone.local(2026, 10, 28, 3)
    latest_time = Time.zone.local(2026, 10, 29, 3)
    older_sync.update!(last_synced_at: older_time)
    latest_sync.update!(last_synced_at: latest_time)

    status = CloudflareTrafficSync.latest_status_for(account)

    assert_equal "Cloudflare", status[:source]
    assert_equal latest_time, status[:last_synced_at]
  end

  private

  def build_sync(account: create_cloudflare_test_account.audit,
    period_start: Date.new(2026, 10, 26),
    period_end: Date.new(2026, 10, 28))
    CloudflareTrafficSync.create!(
      account:,
      zone_id: "zone-123",
      period_start:,
      period_end:
    )
  end
end
end
