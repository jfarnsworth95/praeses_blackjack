class Setting < ApplicationRecord

    MIN_STARTING_MONEY = 10
    MAX_STARING_MONEY = 10000
    MIN_TOTAL_PLAYERS = 1
    MAX_TOTAL_PLAYERS = 9
    MIN_DECK_COUNT = 1
    MAX_DECK_COUNT = 8

    def update_starting_money(new_starting_money)
        # Ensure input always remains in set range
        self.starting_money = [[new_starting_money, MIN_STARTING_MONEY].max, MAX_STARING_MONEY].min
    end

    def update_pc_count(new_pc_count)
        # Ensure input always remains in set range
        self.pc_count = [[new_pc_count, MIN_TOTAL_PLAYERS].max, MAX_TOTAL_PLAYERS].min
    end

    def update_total_players(new_total_players)
        # Ensure input always remains in set range
        self.total_players = [[new_total_players, MIN_TOTAL_PLAYERS].max, MAX_TOTAL_PLAYERS].min
    end

    def update_deck_count(new_deck_count)
        # Ensure input always remains in set range
        self.deck_count = [[new_deck_count, MIN_DECK_COUNT].max, MAX_DECK_COUNT].min
    end
    
end
