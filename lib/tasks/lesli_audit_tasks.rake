namespace :lesli_audit do
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
