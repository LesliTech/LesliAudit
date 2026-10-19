module LesliAudit
    class LogsController < ApplicationController
        before_action :set_log, only: :show

        # GET /logs
        def index
            @logs = respond_with_pagination(LesliAudit::LogService.new(current_user, query).index)
        end

        # GET /logs/:id
        def show
        end

        private

        def set_log
            @log = current_user.logs.find(params[:id])
        end
    end
end
