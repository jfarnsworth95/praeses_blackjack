class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :settings do |t|
      t.string :session_id
      t.integer :starting_money
      t.integer :pc_count, default: 1
      t.integer :total_players, default: 1
      t.integer :deck_count, default: 1
    end
  end
end
