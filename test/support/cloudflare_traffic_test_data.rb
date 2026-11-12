require "securerandom"

module CloudflareTrafficTestData
  def cloudflare_configuration(**overrides)
    defaults = {
      enabled: true,
      token: "test-token",
      zone_id: "zone-123",
      hostnames: [ "example.com" ],
      account_ids: [],
      page_size: 100,
      max_pages: 10,
      backfill_days: 30,
      reimport_days: 3,
      resource_resolver: lambda do |account:, hostname:, path:|
        { resource_type: "Profile", resource_id: 27 }
      end
    }

    LesliAudit::Cloudflare::Configuration.new(**defaults.merge(overrides))
  end

  def create_cloudflare_test_account
    email = "cloudflare-#{SecureRandom.hex(6)}@example.com"
    timestamp = Time.current
    Lesli::Account.insert_all!([ {
      status: "active",
      name: "Cloudflare test account",
      email:,
      region: "america",
      created_at: timestamp,
      updated_at: timestamp
    } ])
    account = Lesli::Account.find_by!(email:)
    LesliAudit::Account.create!(account:, name: account.name)
    account
  end
end
