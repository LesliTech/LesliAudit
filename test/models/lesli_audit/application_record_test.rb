require "test_helper"

module LesliAudit
    class ApplicationRecordTest < ActiveSupport::TestCase
        test "is abstract" do
            assert_predicate LesliAudit::ApplicationRecord, :abstract_class?
        end
    end
end

