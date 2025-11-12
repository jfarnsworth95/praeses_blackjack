class CreateGameSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :game_sessions do |t|
      t.string :session_id
      t.integer :player_turn, default: 0
      t.integer :phase, default: 0

      t.timestamps
    end
  end
end
