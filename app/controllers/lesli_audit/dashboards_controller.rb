module LesliAudit
  class DashboardsController < ApplicationController
    #before_action :set_dashboard, only: %i[ show edit update destroy ]

    # GET /dashboards
    def index
    end

    # GET /dashboards/1
    def show
    end

    # GET /dashboards/new
    def new
      @dashboard = Dashboard.new
    end

    # GET /dashboards/1/edit
    def edit
    end

    # POST /dashboards
    def create
      @dashboard = Dashboard.new(dashboard_params)

      if @dashboard.save
        redirect_to @dashboard, notice: "Dashboard was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /dashboards/1
    def update
      if @dashboard.update(dashboard_params)
        redirect_to @dashboard, notice: "Dashboard was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /dashboards/1
    def destroy
      @dashboard.destroy
      redirect_to dashboards_url, notice: "Dashboard was successfully destroyed.", status: :see_other
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_dashboard
        @dashboard = Dashboard.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def dashboard_params
        params.fetch(:dashboard, {})
      end
  end
end
