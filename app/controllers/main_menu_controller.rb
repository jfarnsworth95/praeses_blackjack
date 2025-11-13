class MainMenuController < ApplicationController
  def index
    @active_session = GameSession.where(session_id: session[:session_id]).where.not(phase: GameSession::PHASE_ALL_PC_BANKRUPT).count > 0
  end
end
