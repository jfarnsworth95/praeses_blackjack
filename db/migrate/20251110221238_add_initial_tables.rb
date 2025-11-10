class AddInitialTables < ActiveRecord::Migration[7.2]
  def change

    create_table :game_session do |t|
      t.string :session_id
      t.integer :player_turn
    end

    create_table :players do |t|
      t.references :game_id, type: :integer, index: true, null: false, foreign_key: { to_table: :game_session, on_delete: :cascade}
      t.integer :money
      t.integer :current_bet, default: 0
      t.string :name
      t.integer :order
      t.boolean :insurance, default: false
      t.boolean :double_down, default: false
      t.boolean :is_ai
    end

    create_table :cards do |t|
      t.references :game_id, type: :integer, index: true, null: false, foreign_key: { to_table: :game_session, on_delete: :cascade}
      t.references :player_id, type: :integer, index: true, foreign_key: { to_table: :players, on_delete: :cascade }
      t.boolean :is_split, default: false
      t.boolean :in_discard, default: false
      t.boolean :in_deck, default: true
      t.boolean :is_ace
      t.string :card
      t.string :value
    end

    create_table :settings do |t|
      t.string :session_id
      t.integer :starting_money
      t.integer :human_count, default: 1
      t.integer :total_players, default: 1
      t.integer :deck_count, default: 1
    end

  end
end
