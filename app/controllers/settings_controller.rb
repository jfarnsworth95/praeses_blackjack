class SettingsController < ApplicationController

    def index
        @settings = Setting.where(session_id: session[:session_id]).first_or_create
    end

    def update
        @settings = Setting.find(params[:id])
        form_data = params[:setting]

        # Ensure default path for Settings isn't abused
        if @settings.session_id != session[:session_id]
            flash[:settings_resp] = "Please don't edit other people's settings."
            redirect_to action: "index"
            return
        end

        # Pass form data to model to ensure only expected ranges are used
        @settings.update_starting_money(form_data[:starting_money].to_i)
        @settings.update_pc_count(form_data[:pc_count].to_i)
        @settings.update_total_players(form_data[:pc_count].to_i > form_data[:total_players].to_i ? form_data[:pc_count].to_i : form_data[:total_players].to_i)
        @settings.update_deck_count(form_data[:deck_count].to_i)
        @settings.save!

        
        flash[:settings_resp] = "Changes saved!"

        redirect_to action: "index"
    end
end
