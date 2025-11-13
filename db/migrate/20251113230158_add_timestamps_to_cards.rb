class AddTimestampsToCards < ActiveRecord::Migration[7.2]
  def change
    add_timestamps :cards, null:true
    Card.update_all(created_at: Time.zone.now, updated_at: Time.zone.now)
    change_column_null(:cards, :created_at, false, Time.zone.now)
    change_column_null(:cards, :updated_at, false, Time.zone.now)
  end
end
