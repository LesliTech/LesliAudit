module LesliAudit
    class AnalyticsController < ApplicationController

        # GET /analytics
        def index
        end

        def visitors
            respond_with_successful(AnalyticService.new(current_user, query).visitors)
        end

        def resourcess
            respond_with_successful(AnalyticService.new(current_user, query).resourcess)
        end

        def users 
            respond_with_successful(AnalyticService.new(current_user, query).users)
        end

        def devices 
            respond_with_successful(AnalyticService.new(current_user, query).devices)
        end

        def controllers 
            respond_with_successful(AnalyticService.new(current_user, query).controllers)
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
