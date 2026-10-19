require "test_helper"

module LesliAudit
    class JobsTest < ActiveSupport::TestCase
        test "retention job delegates with its batch size" do
            received_options = nil

            replacement = ->(**options) { received_options = options }

            replace_singleton_method(LesliAudit::RetentionCleanup, :call, replacement) do
                LesliAudit::RetentionCleanupJob.perform_now(batch_size: 25)
            end

            assert_equal({ batch_size: 25 }, received_options)
        end

        private

        def replace_singleton_method(object, method_name, replacement)
            singleton_class = object.singleton_class
            original_method = singleton_class.instance_method(method_name)
            singleton_class.define_method(method_name, &replacement)
            yield
        ensure
            singleton_class.define_method(method_name, original_method)
        end
    end
end

