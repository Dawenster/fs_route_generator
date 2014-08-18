class RemoveDepartureTimeFromFlights < ActiveRecord::Migration
  def change
    remove_column :flights, :departure_time
  end
end
