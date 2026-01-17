module LesliAudit
  class UserJournalsController < ApplicationController
    before_action :set_user_journal, only: %i[ show edit update destroy ]

    # GET /user_journals
    def index
      @user_journals = UserJournal.all
    end

    # GET /user_journals/1
    def show
    end

    # GET /user_journals/new
    def new
      @user_journal = UserJournal.new
    end

    # GET /user_journals/1/edit
    def edit
    end

    # POST /user_journals
    def create
      @user_journal = UserJournal.new(user_journal_params)

      if @user_journal.save
        redirect_to @user_journal, notice: "User journal was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    # PATCH/PUT /user_journals/1
    def update
      if @user_journal.update(user_journal_params)
        redirect_to @user_journal, notice: "User journal was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    # DELETE /user_journals/1
    def destroy
      @user_journal.destroy!
      redirect_to user_journals_path, notice: "User journal was successfully destroyed.", status: :see_other
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_user_journal
        @user_journal = UserJournal.find(params.expect(:id))
      end

      # Only allow a list of trusted parameters through.
      def user_journal_params
        params.fetch(:user_journal, {})
      end
  end
end
