class Player < ApplicationRecord
  belongs_to :game_session
  has_many :card, dependent: :destroy

  def bet_money!(total_bet)
    self.money -= total_bet
    self.current_bet = total_bet
    self.save!
  end

  def natural_win!
    self.money += (self.current_bet * 2.5).round
    self.save!
  end

  def insurance_win!
    self.money += (self.side_bet * 2)
    self.save!
  end

  def standard_win!
    self.money += (self.current_bet * 2)
    self.save!
  end

  def side_bet!
    side_bet = (self.current_bet.to_f / 2).ceil
    self.money -= side_bet
    self.side_bet = side_bet
    self.save!
  end

  def double_down!
    self.money -= self.current_bet
    self.current_bet += self.current_bet
    self.save!
  end

  def split!
    self.money -= self.current_bet
    self.current_bet += self.current_bet
    self.is_split = true
    card_to_split = Card.where(player: self).last
    card_to_split.is_split = true
    card_to_split.save!
    self.save!
  end

  def double_down_and_split!
    self.money -= self.current_bet * 3
    self.current_bet += self.current_bet * 3
    self.is_split = true
    card_to_split = Card.where(player: self).last
    card_to_split.is_split = true
    card_to_split.save!
    self.save!
  end

  # Reset player booleans for fresh round
  def round_reset
    self.insurance = false
    self.double_down = false
    self.is_split = false
    self.current_bet = false
  end

  def can_bet?(total_bet)
    self.money >= total_bet
  end

  def can_side_bet?
    self.money >= (self.current_bet.to_f / 2).ceil 
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

  def is_dealer?
    self.order == Player.where(game_session: self.game_session).maximum(:order)
  end

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

  def is_player_bankrupt?
    self.money <= 0
  end

end
