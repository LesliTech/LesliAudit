require "test_helper"
require "active_job/test_helper"

module LesliAudit
class CloudflareTrafficSyncJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  test "enqueues recent imports only for configured accounts" do
    configuration = cloudflare_configuration(account_ids: [ 12, 34 ])

    assert_enqueued_jobs 2 do
      CloudflareTrafficSyncJob.enqueue_recent(configuration:)
    end
  end

  test "records a successful import" do
    account = create_cloudflare_test_account
    configuration = cloudflare_configuration
    result = Cloudflare::SyncService::Result.new(
      snapshots_count: 8,
      ignored_paths: []
    )
    service = Object.new
    service.define_singleton_method(:call) { |**| result }

    job = build_job(configuration, service)
    job.perform(
      account.id,
      start_on: Date.new(2026, 10, 27),
      end_on: Date.new(2026, 10, 28)
    )

    sync = CloudflareTrafficSync.find_by!(account: account.audit)
    assert sync.succeeded?
    assert_equal 8, sync.snapshots_count
    assert_not_nil sync.last_synced_at
  end

  test "records a failed import and lets Active Job report it" do
    account = create_cloudflare_test_account
    configuration = cloudflare_configuration
    service = Object.new
    service.define_singleton_method(:call) { |**| raise "provider failed" }
    job = build_job(configuration, service)

    error = assert_raises(RuntimeError) do
      job.perform(
        account.id,
        start_on: Date.new(2026, 10, 27),
        end_on: Date.new(2026, 10, 28)
      )
    end

    sync = CloudflareTrafficSync.find_by!(account: account.audit)
    assert_equal "provider failed", error.message
    assert sync.failed?
    assert_equal "provider failed", sync.error_message
  end

  private

  def build_job(configuration, service)
    CloudflareTrafficSyncJob.new.tap do |job|
      job.define_singleton_method(:traffic_configuration) { configuration }
      job.define_singleton_method(:sync_service) { |_configuration| service }
    end
  end
end
end
