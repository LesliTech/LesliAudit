require "test_helper"

module LesliAudit
    class VersionTest < ActiveSupport::TestCase
        test "has version and build numbers" do
            assert_predicate LesliAudit::VERSION, :present?
            assert_predicate LesliAudit::BUILD, :present?
        end
    end
end

