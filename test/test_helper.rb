ENV["RAILS_ENV"] ||= "test"

require "lesli_testing"

LesliTesting.engine("LesliAudit", {
    coverage_min_coverage: 10,
    coverage_profile: "engine"
})

require_relative "dummy/config/environment"

ActiveRecord::Migrator.migrations_paths = [File.expand_path("dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)

require "rails/test_help"

if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
    fixture_path = File.expand_path("fixtures", __dir__)

    ActiveSupport::TestCase.fixture_paths = [fixture_path]
    ActionDispatch::IntegrationTest.fixture_paths = [fixture_path]
    ActiveSupport::TestCase.file_fixture_path = File.join(fixture_path, "files")
    ActiveSupport::TestCase.fixtures :all
end

module LesliAuditTestData
    def core_account
        @core_account ||= find_or_create_core_account(
            name: "Test Account",
            email: "account-one@example.com"
        )
    end

    def secondary_core_account
        @secondary_core_account ||= find_or_create_core_account(
            name: "Secondary Test Account",
            email: "account-two@example.com"
        )
    end

    def core_user
        @core_user ||= find_or_create_core_user(
            account: core_account,
            first_name: "Test",
            last_name: "User",
            email: "one@example.com",
            uid: "one@example.com"
        )
    end

    def secondary_core_user
        @secondary_core_user ||= find_or_create_core_user(
            account: secondary_core_account,
            first_name: "Secondary",
            last_name: "User",
            email: "two@example.com",
            uid: "two@example.com"
        )
    end

    def audit_account
        LesliAudit::Account.find_or_create_by!(account: core_account) do |account|
            account.name = core_account.name
        end
    end

    def with_audit_config(**overrides)
        configuration = Lesli.config.audit
        original = configuration.dup
        configuration.merge!(overrides)
        yield
    ensure
        configuration.replace(original)
    end

    private

    # Core records are inserted directly so engine tests do not trigger Lesli's
    # account provisioning callbacks or depend on fixtures owned by another gem.
    def find_or_create_core_account(name:, email:)
        Lesli::Account.find_by(email:) || begin
            timestamp = Time.current
            Lesli::Account.insert_all!([{
                status: "active",
                name:,
                email:,
                region: "america",
                created_at: timestamp,
                updated_at: timestamp
            }])
            Lesli::Account.find_by!(email:)
        end
    end

    def find_or_create_core_user(account:, first_name:, last_name:, email:, uid:)
        Lesli::User.find_by(email:) || begin
            timestamp = Time.current
            Lesli::User.insert_all!([{
                account_id: account.id,
                first_name:,
                last_name:,
                email:,
                uid:,
                active: true,
                encrypted_password: "",
                sign_in_count: 0,
                created_at: timestamp,
                updated_at: timestamp
            }])
            Lesli::User.find_by!(email:)
        end
    end
end

ActiveSupport::TestCase.include(LesliAuditTestData)

