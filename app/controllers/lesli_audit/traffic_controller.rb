module LesliAudit
    class TrafficController < ApplicationController
        def index
            service = TrafficService.new(current_user, traffic_query)

            @summary = service.summary
            @traffic = service.traffic
            @paths = service.paths
            @resources = service.resources
            @countries = service.breakdown(:country)
            @devices = service.breakdown(:device)
            @referrers = service.breakdown(:referrer)
        end

        private

        def traffic_query
            params
                .permit(:bytime, :resource_type, :resource_id)
                .to_h
                .symbolize_keys
        end
    end
end
