module LesliAudit
    class TrafficController < ApplicationController
        def index
            dashboard = TrafficService.new(current_user, traffic_query).dashboard

            @summary = dashboard.fetch(:summary)
            @trend = dashboard.fetch(:trend)
            @paths = dashboard.fetch(:paths)
            @resources = dashboard.fetch(:resources)
            @countries = dashboard.fetch(:countries)
            @devices = dashboard.fetch(:devices)
            @referrers = dashboard.fetch(:referrers)
            @synchronization = dashboard.fetch(:synchronization)
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
