class Player < ApplicationRecord
  belongs_to :game_session
  has_many :card, dependent: :destroy

  # Adds player bet
  def bet_money!(total_bet)
    self.money -= total_bet
    self.current_bet = total_bet
    self.save!
  end

  # Natural give you 150% plus your bet back
  def natural_win!
    winnings = (self.current_bet * 2.5).round
    self.money += winnings
    self.save!
    winnings
  end

  # Each split carries an equal amount, 
  # so winning one gets you x2 your bet, or the total of both split bets
  def split_win!
    winnings = self.current_bet
    self.money += self.current_bet
    self.save!
    winnings
  end

  # Side bet more or less gets you back to even. 
  # I'm not doing floats, so you can come out ahead
  def insurance_win!
    winnings = self.side_bet * 2
    self.money += winnings
    self.save!
    winnings
  end

  # Standard win gets you 100% of your bet and the original bet back
  # Side bet is quietly added back since it's really only for insurance
  def standard_win!
    winnings = (self.current_bet * 2) + self.side_bet
    self.money += winnings
    self.save!
    winnings
  end

  # No gain, no loss
  def stand_off!
    self.money += self.current_bet
    self.save!
  end

  # Adds side bet for Insurance phase
  def side_bet!
    side_bet = (self.current_bet.to_f / 2).ceil
    self.money -= side_bet
    self.side_bet = side_bet
    self.save!
  end

  # Double down, doubling the current bet
  def double_down!
    self.money -= self.current_bet
    self.current_bet += self.current_bet
    self.save!
  end

  # Sets up 2 hands for the player, and doubles the bet
  def split!
    self.money -= self.current_bet
    self.current_bet += self.current_bet
    self.is_split = true
    card_to_split = Card.where(player: self).last
    card_to_split.is_split = true
    card_to_split.save!
    self.save!
  end

  # Splits and Double Downs
  # Sets up 2 hands for the player doubling the bet, then doubles the bet of each again
  def double_down_and_split!
    self.money -= self.current_bet * 4
    self.current_bet += self.current_bet * 4
    self.is_split = true
    card_to_split = Card.where(player: self).last
    card_to_split.is_split = true
    card_to_split.save!
    self.save!
  end

  # Reset player booleans for fresh round
  def round_reset!
    self.insurance = false
    self.double_down = false
    self.is_split = false
    self.current_bet = false
    self.save!
  end

  # Validate bet doesn't exceed current money
  def can_bet?(total_bet)
    self.money >= total_bet
  end

  # Validate player can make half their current bet (rounded up)
  def can_side_bet?
    can_bet?((self.current_bet.to_f / 2).ceil )
  end

  # Checks if a player can double down (only possible if cards value 9, 10, or 11)
  def can_double_down?
    hand = Card.where(player: self)
    hand.count == 2 and ([9, 10, 11].include?(self.best_value)) and self.can_bet?(self.current_bet * 3)
  end

  # Check if a player can split (same symbol on both cards)
  def can_split?
    hand = Card.where(player: self)
    hand.count == 2 and !self.is_split and (hand[0].symbol == hand[1].symbol) and self.can_bet?(self.current_bet)
  end

  # Check if a player can double down AND split (requires two 5's)
  def can_double_down_and_split?
    hand = Card.where(player: self)
    hand.count == 2 and (hand.pluck(:value).all? { |value| value == 5 }) and self.can_bet?(self.current_bet)
  end

  # Check if this player is the dealer
  def is_dealer?
    # Dealer is always last in the turn order
    self.order == Player.where(game_session: self.game_session).maximum(:order)
  end

  # Check if the best value of the hand exceeds 21
  def has_bust?(split=false)
    self.best_value(split) > 21
  end

  # Check the player's hand for it's current value, if an Ace would cause a Bust, check again with it as a 1
  def best_value(split=false)
    hand = Card.where(player: self, is_split: split)
    values = hand.pluck(:value)
    while values.sum > 21 and values.include?(11)
      values[values.index(11)] = 1
    end
    return values.sum
  end

  # If player is out of money and has no bets, they're out
  def is_player_out?
    self.money <= 0 and self.current_bet <= 0 and self.side_bet <= 0
  end

end
