module LesliAudit
  class Dashboard::ComponentsController < ApplicationController
    before_action :set_dashboard_component, only: %i[ show edit update destroy ]

    # GET /dashboard/components
    def index
      @dashboard_components = Dashboard::Component.all
    end

    # GET /dashboard/components/1
    def show
    end

    # GET /dashboard/components/new
    def new
      @dashboard_component = Dashboard::Component.new
    end

    # GET /dashboard/components/1/edit
    def edit
    end

    # POST /dashboard/components
    def create
      @dashboard_component = Dashboard::Component.new(dashboard_component_params)

      if @dashboard_component.save
        redirect_to @dashboard_component, notice: "Component was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /dashboard/components/1
    def update
      if @dashboard_component.update(dashboard_component_params)
        redirect_to @dashboard_component, notice: "Component was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /dashboard/components/1
    def destroy
      @dashboard_component.destroy
      redirect_to dashboard_components_url, notice: "Component was successfully destroyed.", status: :see_other
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_dashboard_component
        @dashboard_component = Dashboard::Component.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def dashboard_component_params
        params.fetch(:dashboard_component, {})
      end
  end
end
