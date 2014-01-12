require 'rest_client'

task :ping => :environment do
  current_airports = [
    "ATL",
    "BOS",
    "DTW",
    "EWR",
    "IAH",
    "JFK",
    "LAX",
    "LGA",
    "MIA",
    "ORD",
    "PHX",
    "SEA",
    "SFO",
    "YVR",
    "YYC",
    "YYZ"
  ]
  current_airports.each do |airport_code|
    RestClient.get "http://fs-#{airport_code.downcase}-api.herokuapp.com/mark-flights-as-old"
  end
end