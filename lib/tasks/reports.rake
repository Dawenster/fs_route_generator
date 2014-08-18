require 'csv'

task :load_csvs => :environment do
  Flight.destroy_all

  flight_csvs = Dir['db/blog/inputs/*.csv']
  flight_csvs.each do |flight_csv|
    puts flight_csv
    count = 0
    CSV.foreach(flight_csv) do |row|
      unless count == 0
        Flight.create(
          :departure_airport_id => row[1].to_i,
          :arrival_airport_id => row[2].to_i,
          :departure_time => DateTime.strptime(row[3], "%Y-%m-%d %H:%M:%S"),
          :flight_no => row[6],
          :price => row[7].to_i
        )
      end
      count += 1
    end
  end
end

task :generate_blog_data, [:departure_city] => :environment do |t, args|
  departure_city = args.departure_city

  cities.each do |arrival_city, codes|
    next if departure_city == arrival_city

    city_pairing = "#{departure_city}-#{arrival_city}"
    puts city_pairing

    return_prices = get_return_prices(departure_city, arrival_city)
    oneway_outbound_prices = get_oneway_prices(departure_city, arrival_city)
    oneway_inbound_prices = get_oneway_prices(arrival_city, departure_city)

    CSV.open("db/blog/outputs/#{city_pairing}.csv", "wb") do |csv|
      csv << [
        "Standard outbound",
        "Standard inbound",
        "Shortcut outbound",
        "Shortcut inbound",
        "Lowest standard return",
        "Lowest shortcut return"
      ]

      return_prices.each do |days_from_today, price|
        if days_from_today < 90
          outbound_standard_price = oneway_outbound_prices[days_from_today]
          inbound_standard_price = oneway_inbound_prices[days_from_today + 7]
          two_oneways = outbound_standard_price + inbound_standard_price
          cheapest_standard = [price, two_oneways].min

          outbound_shortcut_price = cheapest_shortcut_flight_price(departure_city, arrival_city, days_from_today, "outbound")
          inbound_shortcut_price = cheapest_shortcut_flight_price(arrival_city, departure_city, days_from_today, "inbound")

          cheapest_shortcut_outbound = [outbound_standard_price, outbound_shortcut_price].min
          cheapest_shortcut_inbound = [inbound_standard_price, inbound_shortcut_price].min
          two_shortcut_oneways = cheapest_shortcut_outbound + cheapest_shortcut_inbound
          cheapest_shortcut = [cheapest_standard, two_shortcut_oneways].min

          csv << [
            outbound_standard_price,
            inbound_standard_price,
            outbound_shortcut_price,
            inbound_shortcut_price,
            cheapest_standard,
            cheapest_shortcut
          ]
        end
      end
    end
  end
end

def cities
  {
    "atlanta" => ["ATL"],
    "boston" => ["BOS"],
    "chicago" => ["ORD", "MDW"],
    "dallas" => ["DFW"],
    "denver" => ["DEN"],
    "honolulu" => ["HNL"],
    "los_angeles" => ["LAX", "LGB"],
    "las_vegas" => ["LAS"],
    "new_york" => ["JFK", "LGA", "EWR"],
    "san_diego" => ["SAN"],
    "san_francisco" => ["SFO", "SJC", "OAK"],
    "seattle" => ["SEA"],
    "washington" => ["IAD", "BWI", "DCA"]
  }
end

def get_return_prices(departure_city, arrival_city)
  return_prices = {}
  count = 0

  CSV.foreach("db/prices/return/#{cities[departure_city].join(',')}-#{cities[arrival_city].join(',')}.csv") do |row|
    unless count == 0
      return_prices[row[0].to_i] = row[1].gsub("US$", "").gsub('"', "").gsub(",", "").to_i
    end
    count += 1
  end
  return return_prices
end

def get_oneway_prices(departure_city, arrival_city)
  oneway_prices = {}
  count = 0

  CSV.foreach("db/prices/oneway/#{cities[departure_city].join(',')}-#{cities[arrival_city].join(',')}.csv") do |row|
    unless count == 0
      oneway_prices[row[0].to_i] = row[1].gsub("US$", "").gsub('"', "").gsub(",", "").to_i
    end
    count += 1
  end
  return oneway_prices
end

def cheapest_shortcut_flight_price(departure_city, arrival_city, days_from_today, segment)
  departure_city_airport_ids = cities[departure_city].map { |code| Airport.find_by_code(code).id }
  arrival_city_airport_ids = cities[arrival_city].map { |code| Airport.find_by_code(code).id }

  start_time = Time.utc(2014, "aug", 18, 0, 0, 0) + days_from_today.days
  start_time += 7.days if segment == "inbound"
  end_time = start_time + 1.day

  flight = Flight.where(
    "departure_airport_id IN (?) AND arrival_airport_id IN (?) AND departure_time > ? AND departure_time < ?",
    departure_city_airport_ids,
    arrival_city_airport_ids,
    start_time,
    end_time
  ).order("price ASC").first

  return flight.nil? ? 99999999 : (flight.price.to_f / 100).round
end










