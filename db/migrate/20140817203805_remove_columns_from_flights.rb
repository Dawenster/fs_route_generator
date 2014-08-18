class RemoveColumnsFromFlights < ActiveRecord::Migration
  def change
    remove_column :flights, :departure_code
    remove_column :flights, :stop_code
    remove_column :flights, :arrival_code
    remove_column :flights, :stops
  end
end
