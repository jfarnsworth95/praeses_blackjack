class Card < ApplicationRecord
  belongs_to :game_session
  belongs_to :player, optional: true

  DECK_SUITES = ["H", "S", "D", "C"]
  DECK_SYMBOLS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
  DECK_VALUES = [2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10, 11]

  # Load one standard deck into the database
  def self.load_deck(game_session)
    4.times do |suite|
      13.times do |x|
        card = Card.create(:game_session => game_session, :symbol => DECK_SYMBOLS[x], :suite => DECK_SUITES[suite], :value => DECK_VALUES[x])
        card.save!
      end
    end
  end
  
end