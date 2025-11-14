class GameSessionsController < ApplicationController

  before_action :check_game_running, except: [:start_game]
  before_action :before_start_game, only: [:start_game]
  before_action :before_phase, except: [:start_game]
  before_action :check_phase_mismatch, except: [:start_game]

  CAUSE_NATURALS = 0
  CAUSE_INSURANCE_NATURAL = 1
  CAUSE_STANDARD = 2

  REQUEST_STAND = 0
  REQUEST_HIT = 1
  REQUEST_DOUBLE_DOWN = 2
  REQUEST_SPLIT = 3
  REQUEST_DOUBLE_DOWN_AND_SPLIT = 4

  # Delete old games if session has some still kicking around
  def before_start_game
    GameSession.where(session_id: session[:session_id]).destroy_all
  end

  # If we navigate to a game phase, but there is no session, redirect to Main Menu
  def check_game_running
    @game_session = GameSession.find_by(session_id: session[:session_id])
    if @game_session == nil
      redirect_to :root
    end
  end

  # Fetch data all the templates crave (needed for reused partial)
  def before_phase
    @settings = Setting.where(session_id: session[:session_id]).first_or_create
    @players = @game_session.player.order(:order)
    @current_player = @players.where(order: @game_session.player_turn).first
    @cards = Card.where(game_session: @game_session).where.not(player: nil).order(:updated_at => :asc)
    @last_bet = [(session[@current_player.name] || 1), @current_player.money].min
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
      ["resolve_phase", "next_round"].include?(param_to_phase) ? nil : redirect_to( action: "resolve_phase")
    when GameSession::PHASE_ALL_PC_BANKRUPT
      (param_to_phase == "all_pc_bankrupt_phase") ? nil : redirect_to( action: "all_pc_bankrupt_phase")
    end

  end

  # Called on "Start Game", initializes models
  def start_game
    @game_session = GameSession.create_game(session[:session_id])
    @settings = Setting.where(session_id: session[:session_id]).first_or_create
    @players = Player.where(game_session: @game_session)

    redirect_to action: "betting_phase"
  end

  # Starting point for Betting Phase
  # Runs AI on their own, stops Out players from playing
  def betting_phase
    if @current_player.is_player_out?
      @game_session.next_player_turn!
      redirect_to action: "betting_phase"
      return
    end
    if @current_player.is_ai
      ai_bet()
      return
    end
  end

  # Called when players make their bet
  def submit_bet
    bet = params[:player][:current_bet].to_i
    # Verify player can afford bet
    if @current_player.can_bet?(bet)

      # Apply change to money and current bet in model
      @current_player.bet_money!(bet)

      # Advance player turn
      @game_session.next_player_turn!
      @players.reload
      session[@current_player.name] = bet
      redirect_to action: "betting_phase"
    else
      flash[:submit_bet_error] = "You don't have enough money to bet that"
      redirect_to action: "betting_phase"
    end
  end

  # If the dealers shown card is an Ace, this optional phase starts
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

      # Normal AI Turn, random selection if they can make the side bet
      if @current_player.can_side_bet?
        rand(2) == 0 ? @current_player.side_bet! : nil
        @game_session.next_player_turn!
        redirect_to action: "insurance_phase"
      end
    end
  end

  # Yes/No for human player adding side bet
  def insurance_response
    if ActiveModel::Type::Boolean.new.cast(params[:use_insurance]) and @current_player.can_side_bet?
      @current_player.side_bet!
    end
    @game_session.next_player_turn!
    redirect_to action: "insurance_phase"
  end

  # Start point for play phase
  def play_phase
    # All AI will act like the dealer, they will never attempt to double down or split
    if @current_player.is_player_out?
        @game_session.next_player_turn!
        redirect_to action: "play_phase"
    elsif @current_player.is_ai
      self.ai_play
    end

  end

  # Process the human player action during play
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

  # Start point for the resolve phase
  def resolve_phase
    # winnings will keep track of money earned, to display on the view
    @winnings = {}

    cause = params[:cause].to_i
    case cause
    when CAUSE_INSURANCE_NATURAL
      flash[:resolve_cause] = "Dealer DID have a Natural... hope you had Insurance."
      self.resolve_insurance_nat
    when CAUSE_NATURALS
      flash[:resolve_cause] = "Someone had a Natural... hope you did too."
      self.resolve_nats
    when CAUSE_STANDARD
      self.resolve_standard
    end
  end

  # Reset round, and check if all human players are out
  def next_round
    @game_session.reset_for_new_round!
    
    if @game_session.are_all_humans_out?
      @game_session.set_phase!(GameSession::PHASE_ALL_PC_BANKRUPT)
      redirect_to action: "all_pc_bankrupt_phase"
    else
      redirect_to action: "betting_phase"
    end
  end

  # Place holder for final phase, active when all humans are out of money
  def all_pc_bankrupt_phase
  end

  private 

  # AI bet, a random value between 1 and the minimum of 500 & the AI's money
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

  # Deals cards right after the Betting Phase
  def deal_cards
    # Deal each player 2 cards, have dealer's (last player) first card face down
    @players[0..-2].each do |player|
      if player.is_player_out?
        next
      end
      @game_session.draw_card!(player)
      @game_session.draw_card!(player)
    end
    @game_session.draw_card!(@players.last, false, true)
    @game_session.draw_card!(@players.last)

    if @game_session.insurance_triggered?
      # If Ace face up for Dealer, go to Insurance:
      @game_session.set_phase!(GameSession::PHASE_INSURANCE)
      redirect_to action: "insurance_phase"
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

  # AI Hit if below 17, and Stand at or above 17
  def ai_play
    while @current_player.best_value < 17
      @game_session.draw_card!(@current_player)
    end
    if @current_player.is_dealer?
      @game_session.set_phase!(GameSession::PHASE_RESOLVE)
      redirect_to action: "resolve_phase", cause: CAUSE_STANDARD
      return
    end
    @game_session.next_player_turn!
    redirect_to action: "play_phase"
    return
  end

  # Process human player requested HIT
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

  # Process human player requested STAND
  def user_req_stand
    if !@game_session.on_player_split and @current_player.is_split
      @game_session.on_player_split = true
      @game_session.save!
    else
      @game_session.next_player_turn!
    end
    redirect_to action: "play_phase"
  end

  # Process human player requested DOUBLE DOWN
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

  # Process human player requested SPLIT
  def user_req_split
    if @current_player.can_split?
      @current_player.split!
    else
      flash[:play_error] = "You cannot split at this time"
    end
    redirect_to action: "play_phase"
  end

  # Process human player requested DOUBLE DOWN & SPLIT
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

  # What to do if the Insurance phase immediately resolved due to Dealer Natural
  def resolve_insurance_nat
    # First response to other natural winners
    @game_session.players_with_natural.each do |player|
      if player.is_dealer?
        next
      end
      @winnings[player.id] = player.stand_off!
      @winnings[player.id] += player.insurance_win!
    end
    (@players - @game_session.players_with_natural).each do |player|
      if player.is_dealer?
        next
      end
      if player.side_bet > 0
        @winnings[player.id] = player.insurance_win!
      end
    end
  end

  # What to do if one or more players have a Natural
  def resolve_nats
    dealer = @game_session.get_dealer
    natural_winners = @game_session.players_with_natural
    dealer_natural = natural_winners.include?(dealer)
    natural_winners.each do |player|
      if player.is_dealer?
        next
      end
      @winnings[player.id] = dealer_natural ? player.stand_off : player.natural_win!
    end
  end

  # What to do if no special cases causing immediate Resolution occurs
  def resolve_standard
    dealer = @game_session.get_dealer
    @players.each do |player|
      if player.is_split
        @winnings[player.id] = @game_session.did_player_win?(dealer, player, false) ? player.split_win! : 0
        @winnings[player.id] += @game_session.did_player_win?(dealer, player, true) ? player.split_win! : 0
      elsif @game_session.did_player_win?(dealer, player)
        @winnings[player.id] = player.standard_win!
      end
    end
  end


end
