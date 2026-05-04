module LesliAudit
    class VisitorsController < ApplicationController

        # GET /analytics
        def index
            @visits = VisitorService.new(current_user, query).visits
            @visitors = VisitorService.new(current_user, query).visitors
            @requests = VisitorService.new(current_user, query).requests
            @browsers = VisitorService.new(current_user, query).browsers
            @devices = VisitorService.new(current_user, query).devices
        end
    end
end
