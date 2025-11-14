class GameSession < ApplicationRecord
    has_many :player, dependent: :destroy
    has_many :card, dependent: :destroy

    DEFAULT_AI_NAMES = ["Arthur", "Sherlock", "Ryan", "Javier", "Leo", "Christine", "Beth", "Brice", "Morgan", "Jamie"]
    PHASE_BETTING = 0
    PHASE_INSURANCE = 1
    PHASE_PLAY = 2
    PHASE_RESOLVE = 3
    PHASE_ALL_PC_BANKRUPT = 4

    def self.create_game(session_id)
        GameSession.transaction do
            # Start Game Session
            @game_session = GameSession.create(:session_id => session_id)
            @game_session.save!

            # Load Settings
            @settings = Setting.where(session_id: session_id).first_or_create

            # Create Players
            create_pcs(@settings.pc_count)
            create_ai(@settings.total_players, @settings.pc_count)

            # Load the Deck(s)
            @settings.deck_count.times do |x|
                Card.load_deck(@game_session)
            end
        end

        @game_session
    end

    def self.create_pcs(total_pcs)
        total_pcs.times do |x|
            Player.create(:game_session => @game_session, :money => @settings.starting_money, :name => "Player #{x + 1}", :order => x, :is_ai => false)
        end
    end

    def self.create_ai(total_players, total_pcs)
        total_ai = total_players - total_pcs
        total_ai.times do |x|
            Player.create(:game_session => @game_session, :money => @settings.starting_money, :name => DEFAULT_AI_NAMES[x], :order => total_pcs + x)
        end
        
        # Add one AI to account for Dealer
        Player.create(:game_session => @game_session, :money => @settings.starting_money, :name => "Dealer", :order => total_players)

    end

    # Draws a card, removes the card from the draw pile, assigns to a player, and CAN assign to a split if one is created
    # Also flip a can face_down (for dealer)
    def draw_card!(player, split=false, dealer_face_down=false)
        deck = Card.where(game_session: self, in_deck: true)
        if deck.count == 0
            self.shuffle_deck!
            deck = Card.where(game_session: self, in_deck: true)
        end
        drawn_card = deck[rand(deck.count)]
        drawn_card.player = player
        drawn_card.is_split = split
        drawn_card.is_face_down = dealer_face_down
        drawn_card.in_deck = false
        drawn_card.save!
    end

    # Discards all cards in play
    def discard_dealt_cards!
        dealt_cards = Card.where(game_session: self).where.not(player: nil)
        dealt_cards.update_all(player_id: nil, in_discard: true)
        dealt_cards.each(&:save)
    end

    def shuffle_deck!
        discard_pile = Card.where(game_session: self, in_discard: true)
        discard_pile.update_all(in_deck: true, in_discard: false)
        discard_pile.each(&:save)
    end

    # Get all players with a Natural for the start of the round
    def players_with_natural
        naturals = []
        self.player.each { |player| 
            Card.where(player: player).pluck(:value).sort == [10, 11] ? naturals.push(player) : nil
        }
        return naturals
    end

    # Check if Insurance can be played (Dealer has faceup ace)
    def insurance_triggered?
        dealer_player = self.get_dealer
        Card.where(player: dealer_player, is_face_down: false).first.symbol == "A"
    end

    def get_dealer
        self.player.order(order: :desc).first
    end

    def set_phase!(phase_id)
        self.player_turn = 0
        self.phase = phase_id
        self.save!
    end

    def next_player_turn!
        self.player_turn += 1
        self.on_player_split = false
        self.save!
    end

    def did_player_win?(dealer, player, split=false)
        dealer_total = dealer.best_value
        !player.has_bust?(split) and (player.best_value(split) > dealer_total or dealer.has_bust?)
    end

    def are_all_humans_out?
        Player.where(game_session: self, is_ai: false).all? { |player| player.is_player_out? }
    end

    def reset_for_new_round!
        self.player.each(&:round_reset!)
        self.discard_dealt_cards!
        self.set_phase!(GameSession::PHASE_BETTING)
    end

end
