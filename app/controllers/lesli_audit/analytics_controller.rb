module LesliAudit
    class AnalyticsController < ApplicationController

        # GET /analytics
        def index
            @visitors = respond_as_successful(AnalyticService.new(current_user, query).visitors)
            @controllers = respond_as_successful(AnalyticService.new(current_user, query).controllers)
            @users = respond_as_successful(AnalyticService.new(current_user, query).users)
        end

        def devices 
            respond_with_successful(AnalyticService.new(current_user, query).devices)
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
