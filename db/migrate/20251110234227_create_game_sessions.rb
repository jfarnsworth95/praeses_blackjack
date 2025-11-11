class CreateGameSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :game_sessions do |t|
      t.string :session_id
      t.integer :player_turn

      t.timestamps
    end
  end
end
