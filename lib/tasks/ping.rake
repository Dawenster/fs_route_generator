require 'rest_client'

task :ping => :environment do
  current_airports = [
    "BOS",
    "JFK",
    "LAX",
    "LGA",
    "ORD",
    "SFO",
    "YVR",
    "YYC",
    "YYZ"
  ]
  current_airports.each do |airport_code|
    RestClient.get "http://fs-#{airport_code.downcase}-api.herokuapp.com/routes-to-scrape"
  end
end