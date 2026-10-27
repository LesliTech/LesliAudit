module LesliAudit
    class LogsController < ApplicationController
        before_action :set_log, only: :show

        # GET /logs
        def index
            @log_kind = log_service.kind
            @available_log_kinds = log_service.available_kinds
            @logs = respond_with_pagination(log_service.index)
        end

        # GET /logs/:id
        def show
        end

        private

        def set_log
            @log_kind = log_service.kind
            @log = log_service.find(params[:id])
        end

        def log_service
            @log_service ||= LesliAudit::LogService.new(
                current_user,
                query.merge(kind: params[:kind])
            )
        end
    end
end
