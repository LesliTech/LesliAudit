module LesliAudit
    class AnalyticsController < ApplicationController

        # GET /analytics
        def index
            dashboard = AnalyticsService.new(current_user, query).dashboard

            @summary = dashboard.fetch(:summary)
            @request_trend = dashboard.fetch(:request_trend)
            @top_controllers = dashboard.fetch(:top_controllers)
            @browsers = dashboard.fetch(:browsers)
            @devices = dashboard.fetch(:devices)
            @operating_systems = dashboard.fetch(:operating_systems)
        end
    end
end
