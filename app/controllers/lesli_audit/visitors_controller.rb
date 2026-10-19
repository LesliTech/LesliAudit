module LesliAudit
    class VisitorsController < ApplicationController

        # GET /analytics
        def index
            @visits = VisitorService.new(current_user, query).visits
            @traffic = VisitorService.new(current_user, query).traffic
            @requests = VisitorService.new(current_user, query).requests
            @browsers = VisitorService.new(current_user, query).browsers
            @devices = VisitorService.new(current_user, query).devices
            @os = VisitorService.new(current_user, query).os
        end
    end
end
