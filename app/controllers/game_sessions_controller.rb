class GameSessionsController < ApplicationController

  before_action :before_start_game, only: [:start_game]
  before_action :before_phase, except: [:start_game]
  before_action :check_phase_mismatch, except: [:start_game]

  CAUSE_NATURALS = 0
  CAUSE_INSURANCE_NATURAL = 1

  REQUEST_STAND = 0
  REQUEST_HIT = 1
  REQUEST_DOUBLE_DOWN = 2
  REQUEST_SPLIT = 3
  REQUEST_DOUBLE_DOWN_AND_SPLIT = 4

  # Delete old games if session has some still kicking around
  def before_start_game
    GameSession.where(session_id: session[:session_id]).destroy_all
  end

  # Fetch data all the templates crave (needed for reused partial)
  def before_phase
    @game_session = GameSession.find_by(session_id: session[:session_id])
    @settings = Setting.where(session_id: session[:session_id]).first_or_create
    @players = Player.where(game_session: @game_session).order(:order)
    @current_player = @players.where(order: @game_session.player_turn).first
    @cards = Card.where(game_session: @game_session).where.not(player: nil)
  end

  # Ensure an API call can't be used to skip around
  def check_phase_mismatch
    param_to_phase = params[:action]

    case @game_session.phase
    when GameSession::PHASE_BETTING
      ["betting_phase", "submit_bet"].include?(param_to_phase) ? nil : redirect_to( action: "betting_phase")
    when GameSession::PHASE_INSURANCE
      ["insurance_phase", "insurance_response"].include?(param_to_phase) ? nil : redirect_to( action: "insurance_phase")
    when GameSession::PHASE_PLAY
      ["play_phase", "play"].include?(param_to_phase) ? nil : redirect_to( action: "play_phase")
    when GameSession::PHASE_RESOLVE
      param_to_phase == "resolve_phase" ? nil : redirect_to( action: "resolve_phase")
    when GameSession::PHASE_ALL_PC_BANKRUPT
      param_to_phase == "all_pc_bankrupt" ? nil : redirect_to( action: "all_pc_bankrupt_phase")
    end

  end

  # Called on "Start Game", initializes models
  def start_game
    @game_session = GameSession.create_game(session[:session_id])
    @settings = Setting.where(session_id: session[:session_id]).first_or_create
    @players = Player.where(game_session: @game_session)

    redirect_to action: "betting_phase"
  end

  def betting_phase
    if @current_player.money <= 0
      @game_session.next_player_turn!
      redirect_to action: "betting_phase"
    end
    if @current_player.is_ai
      ai_bet()
      return
    end
  end

  def submit_bet
    # Verify player can afford bet
    if @current_player.can_bet?(params[:player][:current_bet].to_i )

      # Apply change to money and current bet in model
      @current_player.bet_money!(params[:player][:current_bet].to_i )

      # Advance player turn
      @game_session.next_player_turn!
      @players.reload
      redirect_to action: "betting_phase"
    else
      flash[:submit_bet_error] = "You don't have enough money to bet that"
      redirect_to action: "betting_phase"
    end
  end

  def insurance_phase
    if @current_player.is_ai

      # Resolve Dealer turn for Insurance
      if @current_player.is_dealer?
        if @current_player.best_value == 21
          @game_session.set_phase!(GameSession::PHASE_RESOLVE)
          redirect_to action: "resolve_phase", cause: CAUSE_INSURANCE_NATURAL
        else
          @game_session.set_phase!(GameSession::PHASE_PLAY)
          redirect_to action: "play_phase"
        end
        return
      end

      # Normal AI Turn
      if @current_player.can_side_bet?
        rand(2) == 0 ? @current_player.side_bet! : nil
        @game_session.next_player_turn!
        redirect_to action: "insurance_phase"
      end
    end
  end

  def insurance_response
    if ActiveModel::Type::Boolean.new.cast(params[:use_insurance]) and @current_player.can_side_bet?
      @current_player.side_bet!
    end
    @game_session.next_player_turn!
    redirect_to action: "insurance_phase"
  end

  def play_phase
    # All AI will act like the dealer, they will never attempt to double down or split
    if @current_player.is_ai
      self.ai_play
    end
  end

  def play
    request = params[:request].to_i

    case request
    when REQUEST_STAND
      self.user_req_stand
    when REQUEST_HIT
      self.user_req_hit
    when REQUEST_DOUBLE_DOWN
      self.user_req_double_down
    when REQUEST_SPLIT
      self.user_req_split
    when REQUEST_DOUBLE_DOWN_AND_SPLIT
      self.user_req_double_down_and_split
    end

  end

  def resolve_phase
  end

  def all_pc_bankrupt_phase
  end

  private 

  def ai_bet
    if @current_player.order == @players.pluck(:order).max
      # If dealer, deal cards
      deal_cards()
      return
    end
    bet = rand([@current_player.money, 499].min) + 1
    @current_player.bet_money!(bet)
    @game_session.next_player_turn!
    redirect_to action: "betting_phase"
  end

  def deal_cards
    # Deal each player 2 cards, have dealer's (last player) first card face down
    @players[0..-2].each do |player|
      @game_session.draw_card!(player)
      @game_session.draw_card!(player)
    end
    @game_session.draw_card!(@players.last, false, true)
    @game_session.draw_card!(@players.last)

    if @game_session.insurance_triggered?
      # If Ace face up for Dealer, go to Insurance:
      @game_session.set_phase!(GameSession::PHASE_INSURANCE)
      redirect_to action: "insurance_phase"
      return
    elsif @game_session.players_with_natural.count > 0
      # If anyone has naturals, go to resolve
      @game_session.set_phase!(GameSession::PHASE_RESOLVE)
      redirect_to action: "resolve_phase", cause: CAUSE_NATURALS
    else
      # If no special condition, go to play
      @game_session.set_phase!(GameSession::PHASE_PLAY)
      redirect_to action: "play_phase"
    end
  end

  def ai_play
    while @current_player.best_value < 17
      @game_session.draw_card!(@current_player)
    end
    if @current_player.is_dealer?
      @game_session.set_phase!(GameSession::PHASE_RESOLVE)
      redirect_to action: "resolve_phase"
      return
    end
    @game_session.next_player_turn!
    redirect_to action: "play_phase"
    return
  end

  def user_req_hit
    @game_session.draw_card!(@current_player, @game_session.on_player_split)
    if @current_player.has_bust?(@game_session.on_player_split)
      if @current_player.is_split and !@game_session.on_player_split
        @game_session.on_player_split = true
        @game_session.save!
      else
        @game_session.next_player_turn!
      end
    end
    redirect_to action: "play_phase"
  end

  def user_req_stand
    if !@game_session.on_player_split and @current_player.is_split
      @game_session.on_player_split = true
      @game_session.save!
    else
      @game_session.next_player_turn!
    end
    redirect_to action: "play_phase"
  end

  def user_req_double_down
    if @current_player.can_double_down?
      @current_player.double_down!
      @game_session.draw_card!(@current_player, false, true)
      @game_session.next_player_turn!
    else
      flash[:play_error] = "You cannot double down at this time"
    end
    redirect_to action: "play_phase"
  end

  def user_req_split
    if @current_player.can_split?
      @current_player.split!
    else
      flash[:play_error] = "You cannot split at this time"
    end
    redirect_to action: "play_phase"
  end

  def user_req_double_down_and_split
    if @current_player.can_double_down_and_split?
      @current_player.double_down_and_split!
      @game_session.draw_card!(@current_player, false, true)
      @game_session.draw_card!(@current_player, true, true)
      @game_session.next_player_turn!
    else
      flash[:play_error] = "You cannot double down and split at this time"
    end
    redirect_to action: "play_phase"
  end

end
