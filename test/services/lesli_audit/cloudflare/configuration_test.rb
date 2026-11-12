require "test_helper"

module LesliAudit::Cloudflare
  class ConfigurationTest < ActiveSupport::TestCase
    test "normalizes hostnames and account IDs" do
      configuration = cloudflare_configuration(
        hostnames: [ " EXAMPLE.COM ", "example.com" ],
        account_ids: [ "12", "invalid", 12, "0" ]
      )

      assert_equal [ "example.com" ], configuration.hostnames
      assert_equal [ 12 ], configuration.account_ids
      assert_same configuration, configuration.validate!
    end

    test "requires the provider settings used by the synchronization" do
      token_error = assert_raises(Configuration::Invalid) do
        cloudflare_configuration(token: nil).validate!
      end
      resolver_error = assert_raises(Configuration::Invalid) do
        cloudflare_configuration(resource_resolver: nil).validate!
      end

      assert_match "token is missing", token_error.message
      assert_match "must be callable", resolver_error.message
    end
  end
end
