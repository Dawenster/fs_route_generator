require 'rest_client'

task :ping => :environment do
  current_airports = [
    "ATL",
    "BOS",
    "BWI",
    "DEN",
    "DFW",
    "DTW",
    "EWR",
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
  current_airports.each do |airport_code|
    RestClient.get "http://fs-#{airport_code.downcase}-api.herokuapp.com/mark-flights-as-old"
  end
end