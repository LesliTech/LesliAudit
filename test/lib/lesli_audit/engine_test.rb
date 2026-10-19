require "test_helper"

module LesliAudit
    class EngineTest < ActiveSupport::TestCase
        test "inherits from Rails engine and isolates its namespace" do
            assert_operator LesliAudit::Engine, :<, Rails::Engine
            assert_equal "LesliAudit", LesliAudit::Engine.railtie_namespace.name
        end

        test "defines the supported interface routes" do
            route_names = LesliAudit::Engine.routes.routes.filter_map(&:name)

            %w[users analytics visitors logs log requests].each do |route_name|
                assert_includes route_names, route_name
            end
        end

        test "installs its associations on core models" do
            assert_operator Lesli::Account, :<, LesliAudit::AccountAssociations
            assert_operator Lesli::User, :<, LesliAudit::UserAssociations
            assert_equal "LesliAudit::Account", Lesli::Account.reflect_on_association(:audit).class_name
            assert_equal "LesliAudit::UserJournal", Lesli::User.reflect_on_association(:journals).class_name
            assert_equal "LesliAudit::UserRequest", Lesli::User.reflect_on_association(:requests).class_name
            assert_equal "LesliAudit::UserLog", Lesli::User.reflect_on_association(:logs).class_name
        end
    end
end

