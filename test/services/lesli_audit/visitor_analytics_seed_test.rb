require "test_helper"

module LesliAudit
    class VisitorAnalyticsSeedTest < ActiveSupport::TestCase
        test "demo visitor analytics seed is complete and idempotent" do
            audit_account
            seed = LesliAudit::Engine.root.join("db", "seed", "visitor_analytics.rb")

            assert_difference -> { LesliAudit::VisitorRollup.count }, 90 do
                assert_difference -> { LesliAudit::VisitorBreakdown.count }, 900 do
                    load seed
                end
            end

            assert_no_difference -> { LesliAudit::VisitorRollup.count } do
                assert_no_difference -> { LesliAudit::VisitorBreakdown.count } do
                    load seed
                end
            end

            assert_equal ["Business", "Event", "Profile"],
                LesliAudit::VisitorRollup.distinct.order(:resource_type).pluck(:resource_type)
            assert_equal ["country", "device", "referrer"],
                LesliAudit::VisitorBreakdown.distinct.order(:dimension).pluck(:dimension)
        end
    end
end
