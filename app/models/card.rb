class Card < ApplicationRecord
  belongs_to :game_session
  belongs_to :player
end
