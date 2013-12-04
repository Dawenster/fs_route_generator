class CreateFlights < ActiveRecord::Migration
  def change
    create_table :flights do |t|
      t.string :departure_time
      t.string :departure_code
      t.string :stop_code
      t.string :arrival_code
      t.string :flight_no
      t.integer :price
      t.integer :stops
    end
  end
end
