class CreateCards < ActiveRecord::Migration[7.2]
  def change
    create_table :cards do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :player, foreign_key: true, null: true
      t.boolean :is_split, default: false
      t.boolean :in_discard, default: false
      t.boolean :in_deck, default: true
      t.boolean :is_face_down, default: false
      t.string :symbol
      t.string :suite
      t.integer :value
    end
  end
end
