module LesliAudit
    module AppendOnly
        extend ActiveSupport::Concern

        # New records remain writable until their first INSERT. Once persisted,
        # Active Record blocks ordinary updates and destroys. Retention cleanup
        # and tenant hard-purge foreign keys intentionally operate below models.
        def readonly?
            persisted? || super
        end
    end
end
