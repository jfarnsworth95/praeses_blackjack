class CreatePlayers < ActiveRecord::Migration[7.2]
  def change
    create_table :players do |t|
      t.references :game_session, null: false, foreign_key: true
      t.integer :money
      t.integer :current_bet, default: 0
      t.string :name
      t.integer :order
      t.boolean :insurance, default: false
      t.boolean :double_down, default: false
      t.boolean :is_ai
    end
  end
end
