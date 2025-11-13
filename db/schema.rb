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

ActiveRecord::Schema[7.2].define(version: 2025_11_13_230158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cards", force: :cascade do |t|
    t.bigint "game_session_id", null: false
    t.bigint "player_id"
    t.boolean "is_split", default: false
    t.boolean "in_discard", default: false
    t.boolean "in_deck", default: true
    t.boolean "is_face_down", default: false
    t.string "symbol"
    t.string "suite"
    t.integer "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id"], name: "index_cards_on_game_session_id"
    t.index ["player_id"], name: "index_cards_on_player_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.string "session_id"
    t.integer "player_turn", default: 0
    t.boolean "on_player_split", default: false
    t.integer "phase", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.bigint "game_session_id", null: false
    t.integer "money"
    t.integer "current_bet", default: 0
    t.integer "side_bet", default: 0
    t.string "name"
    t.integer "order"
    t.boolean "insurance", default: false
    t.boolean "double_down", default: false
    t.boolean "is_split", default: false
    t.boolean "is_ai", default: true
    t.index ["game_session_id"], name: "index_players_on_game_session_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "session_id"
    t.integer "starting_money", default: 1000
    t.integer "pc_count", default: 1
    t.integer "total_players", default: 1
    t.integer "deck_count", default: 1
  end

  add_foreign_key "cards", "game_sessions"
  add_foreign_key "cards", "players"
  add_foreign_key "players", "game_sessions"
end
