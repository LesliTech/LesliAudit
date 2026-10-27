require "test_helper"

module LesliAudit
    class UsersControllerTest < ActiveSupport::TestCase
        test "assigns every section from the account user dashboard" do
            audit_account
            controller = LesliAudit::UsersController.new
            user = core_user
            query = {}
            controller.define_singleton_method(:current_user) { user }
            controller.define_singleton_method(:query) { query }

            controller.index

            assert controller.instance_variable_get(:@summary).key?(:registered)
            assert controller.instance_variable_get(:@attention).key?(:locked)
            assert_equal 12, controller.instance_variable_get(:@registrations).length
            assert_kind_of Array, controller.instance_variable_get(:@working_hours)
        end
    end
end
