class CreateCards < ActiveRecord::Migration[7.2]
  def change
    create_table :cards do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.boolean :is_split, default: false
      t.boolean :in_discard, default: false
      t.boolean :in_deck, default: false
      t.boolean :is_ace, default: false
      t.string :card_symbol
      t.integer :value
    end
  end
end
