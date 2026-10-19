module LesliAudit
    # Scheduling belongs to the host application. This job only provides a
    # backend-agnostic Active Job entry point for its scheduler.
    class RetentionCleanupJob < ApplicationJob
        def perform(batch_size: LesliAudit::RetentionCleanup::DEFAULT_BATCH_SIZE)
            LesliAudit::RetentionCleanup.call(batch_size: batch_size)
        end
    end
end
