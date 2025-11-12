class GameSession < ApplicationRecord
    has_many :player
    has_many :card

    DEFAULT_AI_NAMES = ["Arthur", "Sherlock", "Ryan", "Javier", "Leo", "Christine", "Beth", "Brice", "Morgan", "Jamie"]

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
    end

    # Draws a card, removes the card from the draw pile, assigns to a player, and CAN assign to a split if one is created
    # Also flip a can face_down (for dealer)
    def self.draw_card!(player, split=false, dealer_face_down=false)
        deck = Card.where(game_session: self, in_deck: true)
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

    # Get all players with a Natural for the start of the round
    def players_with_natural
        naturals = []
        Player.where(game_session: self).each { |player| 
            Card.where(player: player).pluck(:value).sort == [10, 11] ? naturals.push(player) : nil
        }
        return naturals
    end

    # Check if Insurance can be played (Dealer has faceup ace)
    def self.insurance_triggered?()
        Player.where(game_session: self).maximum(:order)
        Card.where(player: dealer_player, is_face_down: false).first.symbol == "A"
    end


end
