require "test_helper"

module LesliAudit
    class UserAgentParserTest < ActiveSupport::TestCase
        test "normalizes browser and operating system metadata" do
            user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                "AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36"

            parsed = LesliAudit::UserAgentParser.parse(user_agent)

            assert_equal "Mac", parsed[:platform]
            assert_equal "10.15.7", parsed[:os]
            assert_equal "Chrome", parsed[:browser]
            assert_equal "140.0.0.0", parsed[:version]
            assert_equal "desktop", parsed[:device]
        end

        test "returns the complete contract for an empty user agent" do
            parsed = LesliAudit::UserAgentParser.parse(nil)

            assert_equal %i[platform os browser version device], parsed.keys
            assert parsed.values.all?(&:nil?)
        end
    end
end
