require 'rest_client'

task :ping => :environment do
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
    "MDW",
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
  current_airports.each do |airport_code|
    RestClient.get "http://fs-#{airport_code.downcase}-api.herokuapp.com/mark-flights-as-old"
  end
end