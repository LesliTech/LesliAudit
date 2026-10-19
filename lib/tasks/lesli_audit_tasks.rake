namespace :lesli_audit do
    namespace :analytics do
        desc "Enqueue durable request events that have not been processed"
        task retry_pending: :environment do
            enqueued = 0

            LesliAudit::UserJournal.pending.in_batches(of: 1_000) do |batch|
                batch.pluck(:id).each do |journal_id|
                    LesliAudit::RequestAnalyticsJob.perform_later(journal_id)
                    enqueued += 1
                end
            end

            puts "#{enqueued} pending request events enqueued"
        end
    end

    namespace :retention do
        desc "Delete expired LesliAudit data using the configured retention policy"
        task cleanup: :environment do
            deleted = LesliAudit::RetentionCleanup.call

            deleted.each do |table, count|
                puts "#{table}: #{count} deleted"
            end
        end
    end
end
