module LesliAudit
    # Processes a durable request event outside the controller response. All
    # counter updates and the processed marker share one transaction, so a retry
    # cannot partially or repeatedly increment analytics.
    class RequestAnalyticsJob < ApplicationJob
        retry_on StandardError, wait: :polynomially_longer, attempts: 10

        def perform(journal_id)
            LesliAudit::RequestAnalytics.process!(journal_id)
        end
    end
end
