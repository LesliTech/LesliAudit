module LesliAudit
    class PublicAnalyticsController < ApplicationController
        def index
            service = PublicAnalyticsService.new(current_user, analytics_query)

            @summary = service.summary
            @traffic = service.traffic
            @resources = service.resources
            @countries = service.breakdown(:country)
            @devices = service.breakdown(:device)
            @referrers = service.breakdown(:referrer)
        end

        private

        def analytics_query
            params
                .permit(:bytime, :resource_type, :resource_id)
                .to_h
                .symbolize_keys
        end
    end
end
