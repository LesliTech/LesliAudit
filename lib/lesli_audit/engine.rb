module LesliAudit
    class Engine < ::Rails::Engine
        isolate_namespace LesliAudit

        initializer :lesli_admin do |app|

            # register assets manifest
            config.assets.precompile += %w[lesli_audit_manifest.js]

            app.config.assets.paths << root.join("app", "javascript").to_s

            # register engine migrations path
            unless app.root.to_s.match root.to_s
                config.paths["db/migrate"].expanded.each do |expanded_path|
                    app.config.paths["db/migrate"] << expanded_path
                end
            end
        end
    end
end
