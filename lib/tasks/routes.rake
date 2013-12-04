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

task :routes_to_scrape, [:origin_code, :destination_code]  => :environment  do |t, args|
  origin = Airport.find_by_code(args.origin_code)
  actual_destination = Airport.find_by_code(args.destination_code)

  possible_destinations(actual_destination)

  hit_matrix(origin.code, "", actual_destination.code, "2013-12-04")
end

def hit_matrix(origin, transfer, destination, date)
  inputs = <<-eos
  {
    'slices' => [{
      'origins':[#{origin}],
      'originPreferCity':true,
      #{format_transfer_city(transfer)}destinations:[#{destination}],
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

  search_result = RestClient.get(url, :params => params )
  search_result[0..3] = ""
  result = JSON.parse(search_result)
  puts result["result"]["id"]
end

def possible_destinations(destination)
  destinations = Airport.where(
    "latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?",
    destination.latitude - 30, destination.latitude + 30, destination.longitude - 30, destination.longitude + 30
  )
  return destinations.map{ |d| d.code }.join(", ")
end

def format_transfer_city(city)
  return "" if city.blank?
  return "X:#{},"
end

# def header
#   return {
#     :content_type => :json,
#     "Connection" => "keep-alive",
#     "Accept" => "*/*",
#     "Accept-Charset" => "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
#     "Accept-Language" => "en-US,en;q=0.8,zh-TW;q=0.6,zh;q=0.4,en-CA;q=0.2",
#     "Cookie" => "PREF=\"ID=0\"",
#     "DNT" => "1"
#   }
# end