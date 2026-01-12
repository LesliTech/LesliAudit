module LesliAudit
    class AnalyticsController < ApplicationController

        # GET /analytics
        def index
            @visitors = AnalyticService.new(current_user, query).visitors
            @controllers = AnalyticService.new(current_user, query).controllers
            @users = AnalyticService.new(current_user, query).users
            @devices = AnalyticService.new(current_user, query).devices
        end

        def devices 
            AnalyticService.new(current_user, query).devices
        end

        private

        # Use callbacks to share common setup or constraints between actions.
        def set_analytic
        end

        # Only allow a list of trusted parameters through.
        def analytic_params
            params.fetch(:analytic, {})
        end
    end
end
