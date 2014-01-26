require "csv"

task :create_airports => :environment do
  CSV.foreach('db/airports.csv') do |row|
    Airport.create( :city => row[0].strip,
                    :name => row[1].strip,
                    :code => row[2].strip,
                    :latitude => row[3].strip.to_f,
                    :longitude => row[4].strip.to_f,
                    :timezone => row[5].strip)
  end
end

task :routes_to_scrape, [:origin_code]  => :environment  do |t, args|
  start_time = Time.now

  current_airports = [
    "ATL",
    "BOS",
    "BWI",
    "DCA",
    "DEN",
    "DFW",
    "DTW",
    "EWR",
    "IAD",
    "IAH",
    "JFK",
    "LAS",
    "LAX",
    "LGA",
    "LGB",
    "MIA",
    "OAK",
    "ORD",
    "PHX",
    "SEA",
    "SFO",
    "SJC",
    "YVR",
    "YYC",
    "YYZ"
  ]
  origin = Airport.find_by_code(args.origin_code)

  current_airports.each do |destination_code|
    actual_destination = Airport.find_by_code(destination_code)
    date_array = dates_to_scrape
    num_days_count = date_array.size
    get_shortcuts(date_array, origin, actual_destination, num_days_count)
    get_shortcuts(date_array, actual_destination, origin, num_days_count)
  end

  time = (Time.now - start_time).to_i
  puts "*" * 100
  puts "Total time: #{time / 60} minutes, #{time % 60} seconds"
end

task :two_city_scrape, [:origin_code, :destination_code]  => :environment  do |t, args|
  start_time = Time.now

  origin = Airport.find_by_code(args.origin_code)
  actual_destination = Airport.find_by_code(args.destination_code)

  date_array = dates_to_scrape
  num_days_count = date_array.size
  get_shortcuts(date_array, origin, actual_destination, num_days_count)
  get_shortcuts(date_array, actual_destination, origin, num_days_count)

  time = (Time.now - start_time).to_i
  puts "*" * 100
  puts "Total time: #{time / 60} minutes, #{time % 60} seconds"
end

def dates_to_scrape
  date_array = []
  num_days = [1, 2, 3, 5, 7, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
  num_days.each do |num|
    date_array << (Time.now + num.days).strftime("%Y-%m-%d")
  end
  return date_array
end

def get_shortcuts(date_array, origin, actual_destination, num_days_count)
  shortcuts = []
  date_array.each_with_index do |date, i|
    puts "*" * 100
    puts "Scraping #{origin.code}-#{actual_destination.code} #{date} (#{i + 1} / #{num_days_count})"

    begin
      results = hit_matrix(origin.code, "", actual_destination.code, date)
      if results
        results.first(100).each do |flight|
          create_flight(flight, origin.code, actual_destination.code, "original")
        end
      end
    rescue
      puts "%%% WTF! ERROR OCCURED! %%%"
    end

    begin
      results = hit_matrix(origin.code, actual_destination.code, possible_destinations(actual_destination), date)
      if results
        results.first(100).each do |flight|
          create_flight(flight, origin.code, actual_destination.code, "shortcut")
        end
      end
    rescue
      puts "%%% WTF! ERROR OCCURED! %%%"
    end

    puts "Routes with shortcuts"
    shortcuts += calculate_shortcuts(origin.code, actual_destination.code)
    puts "No shortcuts found" if shortcuts.empty?
    Flight.destroy_all
  end
  puts "Writing to CSV"
  write_to_csv(shortcuts, origin.code, actual_destination.code)
end

def create_flight(flight, origin, actual_destination, type)
  if type == "original" && flight["itinerary"]["slices"][0]["stops"] == nil
    Flight.create(
      :departure_time => DateTime.strptime(flight["itinerary"]["slices"][0]["departure"], '%Y-%m-%dT%H:%M%z'),
      :departure_code => origin,
      :stop_code => nil,
      :arrival_code => actual_destination,
      :flight_no => flight["itinerary"]["slices"][0]["flights"][0],
      :price => (flight["ext"]["totalPrice"][3..-1].to_f * 100).to_i,
      :stops => 0
    )
  elsif type == "shortcut" && flight["itinerary"]["slices"][0]["stops"].count == 1
    price = 
    Flight.create(
      :departure_time => DateTime.strptime(flight["itinerary"]["slices"][0]["departure"], '%Y-%m-%dT%H:%M%z'),
      :departure_code => origin,
      :stop_code => actual_destination,
      :arrival_code => flight["itinerary"]["slices"][0]["destination"]["code"],
      :flight_no => flight["itinerary"]["slices"][0]["flights"][0],
      :price => (flight["ext"]["totalPrice"][3..-1].to_f * 100).to_i,
      :stops => 1
    )
  end
end

def calculate_shortcuts(origin_code, destination_code)
  all_flights = Flight.all
  non_stop_flights = Flight.where(:stops => 0)
  one_stop_flights = Flight.where(:stops => 1)
  shortcuts = []

  non_stop_flights.each do |flight|
    similar_flights = all_flights.select { |all_flight| all_flight.flight_no == flight.flight_no && all_flight.departure_time == flight.departure_time }
    similar_flights = similar_flights.sort_by { |flight| flight.price }

    cheapest_flight = similar_flights.first
    non_stop_flight = similar_flights.find {|f| f.stops == 0 }

    if non_stop_flight && cheapest_flight.price < (non_stop_flight.price - 2000) && cheapest_flight.stops == 1
      puts "#{cheapest_flight.departure_code}-#{cheapest_flight.arrival_code}"
      # shortcuts << [cheapest_flight.departure_code, cheapest_flight.arrival_code, cheapest_flight.price]
      shortcuts << [cheapest_flight.departure_code, cheapest_flight.arrival_code]
    end
  end
  shortcuts
end

def write_to_csv(shortcuts, origin_code, destination_code)
  CSV.open("db/routes/#{origin_code}/#{origin_code}-#{destination_code}.csv", "wb") do |csv|
    csv << [origin_code, destination_code]
    shortcuts.uniq.each do |shortcut|
      csv << shortcut
    end
  end
end

def hit_matrix(origin, transfer, destination, date)
  inputs = <<-eos
  {
    'slices' => [{
      'origins':[#{origin}],
      'originPreferCity':true,
      #{format_transfer_city(transfer)}'destinations':[#{destination}],
      'destinationPreferCity':false,
      'date':#{date},
      'isArrivalDate':false,
      'dateModifier':{'minus':0,'plus':0}
    }],
    'pax':{'adults':1},
    'cabin':'COACH',
    'changeOfAirport':true,
    'checkAvailability':true,
    'page':{'size':500},
    'sorts':'default'
  }
  eos

  url = "http://matrix.itasoftware.com/xhr/shop/search"

  params = {
    "summarizers" => "carrierStopMatrix,currencyNotice,solutionList,itineraryPriceSlider,itineraryCarrierList,itineraryDepartureTimeRanges,itineraryArrivalTimeRanges,durationSliderItinerary,itineraryOrigins,itineraryDestinations,itineraryStopCountList,warningsItinerary",
    "inputs" => inputs.delete("\n").gsub(" ",""),
    "format" => "JSON",
    "name" => "specificDates"
  }

  search_result = RestClient.post(url, params, header)
  search_result[0..3] = ""
  JSON.parse(search_result)["result"]["solutionList"]["solutions"]
end

def possible_destinations(destination)
  degrees = 30
  destinations = Airport.where(
    "latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?",
    destination.latitude - degrees, destination.latitude + degrees, destination.longitude - degrees, destination.longitude + degrees
  )
  return destinations.map{ |d| "'#{d.code}'" }.join(",")
end

def format_transfer_city(city)
  return "" if city.blank?
  return "'routeLanguage':'X:#{city}',"
end

def header
  return {
    :content_type => :json,
    "Connection" => "keep-alive",
    "Accept" => "*/*",
    "Accept-Charset" => "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
    "Accept-Language" => "en-US,en;q=0.8,zh-TW;q=0.6,zh;q=0.4,en-CA;q=0.2",
    "Cookie" => "PREF=\"ID=0\"",
    "DNT" => "1"
  }
end