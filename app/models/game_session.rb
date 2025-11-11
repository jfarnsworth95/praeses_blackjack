class GameSession < ApplicationRecord
    has_many :player
    has_many :card
end
