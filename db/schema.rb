# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_11_10_221238) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cards", force: :cascade do |t|
    t.integer "game_id_id", null: false
    t.integer "player_id_id"
    t.boolean "is_split", default: false
    t.boolean "in_discard", default: false
    t.boolean "in_deck", default: true
    t.boolean "is_ace"
    t.string "card"
    t.string "value"
    t.index ["game_id_id"], name: "index_cards_on_game_id_id"
    t.index ["player_id_id"], name: "index_cards_on_player_id_id"
  end

  create_table "game_session", force: :cascade do |t|
    t.string "session_id"
    t.integer "player_turn"
  end

  create_table "players", force: :cascade do |t|
    t.integer "game_id_id", null: false
    t.integer "money"
    t.integer "current_bet", default: 0
    t.string "name"
    t.integer "order"
    t.boolean "insurance", default: false
    t.boolean "double_down", default: false
    t.boolean "is_ai"
    t.index ["game_id_id"], name: "index_players_on_game_id_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "session_id"
    t.integer "starting_money"
    t.integer "human_count", default: 1
    t.integer "total_players", default: 1
    t.integer "deck_count", default: 1
  end

  add_foreign_key "cards", "game_session", column: "game_id_id", on_delete: :cascade
  add_foreign_key "cards", "players", column: "player_id_id", on_delete: :cascade
  add_foreign_key "players", "game_session", column: "game_id_id", on_delete: :cascade
end
