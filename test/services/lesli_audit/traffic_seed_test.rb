require "test_helper"

module LesliAudit
    class TrafficSeedTest < ActiveSupport::TestCase
        test "demo traffic seed is complete and idempotent" do
            audit_account
            seed = LesliAudit::Engine.root.join("db", "seed", "traffic.rb")

            assert_difference -> { LesliAudit::TrafficRollup.count }, 300 do
                assert_difference -> { LesliAudit::TrafficBreakdown.count }, 3_000 do
                    load seed
                end
            end

            assert_no_difference -> { LesliAudit::TrafficRollup.count } do
                assert_no_difference -> { LesliAudit::TrafficBreakdown.count } do
                    load seed
                end
            end

            assert_equal [ "Business", "Event", "Profile" ],
                LesliAudit::TrafficRollup.distinct.order(:resource_type).pluck(:resource_type)
            assert_equal [ "country", "device", "referrer" ],
                LesliAudit::TrafficBreakdown.distinct.order(:dimension).pluck(:dimension)
            assert_equal 10, LesliAudit::TrafficRollup.distinct.count(:path)
        end
    end
end
