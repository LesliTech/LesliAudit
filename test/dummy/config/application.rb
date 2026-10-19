require_relative "boot"

require "rails/all"
require "lesli"

Bundler.require(*Rails.groups)

module Dummy
    class Application < Rails::Application
        config.root = File.expand_path("..", __dir__)
        config.load_defaults Rails::VERSION::STRING.to_f
        config.action_controller.include_all_helpers = false
        config.autoload_lib(ignore: %w[assets tasks])
        config.active_job.queue_adapter = :test
    end
end

