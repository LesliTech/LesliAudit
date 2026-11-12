require "securerandom"

module LesliAudit
  class CloudflareTrafficSync < ApplicationRecord
    SOURCE = "Cloudflare"
    RUNNING_TIMEOUT = 2.hours
    MAX_ERROR_LENGTH = 2_000

    belongs_to :account,
      class_name: "LesliAudit::Account",
      inverse_of: :cloudflare_traffic_syncs

    enum :status, {
      pending: "pending",
      running: "running",
      succeeded: "succeeded",
      failed: "failed"
    }

    validates :zone_id, :period_start, :period_end, presence: true
    validates :snapshots_count,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validate :period_ends_after_it_starts

    def self.latest_status_for(account)
      {
        source: SOURCE,
        last_synced_at: where(account:).maximum(:last_synced_at)
      }
    end

    # The row lock lets only one worker own this exact account, zone, and period.
    # The execution ID prevents an old worker from finishing a newer retry.
    def acquire!(at: Time.current)
      new_execution_id = SecureRandom.uuid

      with_lock do
        return if active_execution?(at)

        update!(
          status: :running,
          execution_id: new_execution_id,
          started_at: at,
          finished_at: nil,
          snapshots_count: 0,
          error_message: nil
        )
      end

      new_execution_id
    end

    def complete!(execution_id:, snapshots_count:, at: Time.current)
      finish_execution(execution_id) do
        update!(
          status: :succeeded,
          execution_id: nil,
          snapshots_count:,
          finished_at: at,
          last_synced_at: at,
          error_message: nil
        )
      end
    end

    def fail!(execution_id:, error:, at: Time.current)
      finish_execution(execution_id) do
        update!(
          status: :failed,
          execution_id: nil,
          finished_at: at,
          error_message: error.message.to_s.first(MAX_ERROR_LENGTH)
        )
      end
    end

    private

    def period_ends_after_it_starts
      return if period_start.blank? || period_end.blank? || period_start <= period_end

      errors.add(:period_end, "must be on or after period_start")
    end

    def finish_execution(expected_execution_id)
      with_lock do
        return false unless running? && execution_id == expected_execution_id

        yield
      end

      true
    end

    def active_execution?(at)
      running? && started_at.present? && started_at >= RUNNING_TIMEOUT.ago(at)
    end
  end
end
