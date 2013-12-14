require 'rest_client'

task :ping => :environment do
  current_airports = [
    "ORD",
    "SFO",
    "YVR",
    "YYC",
    "YYZ"
  ]
  current_airports.each do |airport_code|
    RestClient.get "http://fs-#{airport_code.downcase}-api/routes_to_scrape"
  end
end