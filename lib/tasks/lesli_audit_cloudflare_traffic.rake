namespace :cloudflare_traffic do
  desc "Enqueue recent Cloudflare traffic for every configured account"
  task sync: :environment do
    LesliAudit::CloudflareTrafficSyncJob.enqueue_recent
  end

  desc "Enqueue the initial Cloudflare traffic backfill"
  task :backfill, %i[account_id days] => :environment do |_task, arguments|
    account_ids = arguments[:account_id].presence ||
      LesliAudit::Cloudflare::Configuration.from_application.account_ids

    Array(account_ids).each do |account_id|
      LesliAudit::CloudflareTrafficSyncJob.enqueue_backfill(account_id, days: arguments[:days])
    end
  end
end
