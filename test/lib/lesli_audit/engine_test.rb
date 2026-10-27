require "test_helper"

module LesliAudit
    class EngineTest < ActiveSupport::TestCase
        test "inherits from Rails engine and isolates its namespace" do
            assert_operator LesliAudit::Engine, :<, Rails::Engine
            assert_equal "LesliAudit", LesliAudit::Engine.railtie_namespace.name
        end

        test "defines the supported interface routes" do
            route_names = LesliAudit::Engine.routes.routes.filter_map(&:name)

            %w[users analytics traffic_index requests logs log].each do |route_name|
                assert_includes route_names, route_name
            end

            assert_equal "/audit/analytics", LesliAudit::Engine.routes.url_helpers.analytics_path
            assert_equal "/audit/traffic", LesliAudit::Engine.routes.url_helpers.traffic_index_path

            analytics_route = LesliAudit::Engine.routes.routes.find { |route| route.name == "analytics" }
            assert_equal "lesli_audit/analytics", analytics_route.defaults[:controller]

            traffic_route = LesliAudit::Engine.routes.routes.find { |route| route.name == "traffic_index" }
            assert_equal "lesli_audit/traffic", traffic_route.defaults[:controller]
        end

        test "navigation keeps the definitive resource order" do
            navigation = LesliAudit::Engine.root
                .join("app/views/lesli_audit/partials/_navigation.html.erb")
                .read

            helpers = %w[users_path analytics_path traffic_index_path requests_path logs_path]
            positions = helpers.map { |helper| navigation.index("lesli_audit.#{helper}") }

            assert positions.all?
            assert_equal positions.sort, positions
        end

        test "navigation labels contain one word in every locale" do
            %i[en es fr it pt].each do |locale|
                %i[users analytics traffic requests logs].each do |resource|
                    label = I18n.t("lesli_audit.#{resource}.navigation", locale:)

                    assert_no_match(/\s/, label)
                end
            end
        end

        test "core models expose the associations backed by LesliAudit" do
            assert_equal "LesliAudit::Account", Lesli::Account.reflect_on_association(:audit).class_name
            assert_equal "LesliAudit::UserJournal", Lesli::User.reflect_on_association(:journals).class_name
            assert_equal "LesliAudit::UserRequest", Lesli::User.reflect_on_association(:requests).class_name
            assert_equal "LesliAudit::UserLog", Lesli::User.reflect_on_association(:logs).class_name
            assert_equal "LesliAudit::AccountLog", Lesli::User.reflect_on_association(:account_logs).class_name
        end
    end
end
