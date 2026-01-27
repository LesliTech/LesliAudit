module LesliAudit
    class LogsController < ApplicationController
        before_action :set_log, only: %i[ show ]

        # GET /logs
        def index
            @logs = respond_with_pagination(LesliAudit::LogService.new(current_user, query).index)
        end

        # GET /logs/1
        def show
        end

        private

        def set_log
            @log = Log.find(params.expect(:id))
        end

        # Only allow a list of trusted parameters through.
        def log_params
            params.fetch(:log, {})
        end
    end
end
