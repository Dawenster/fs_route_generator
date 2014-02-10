require 'rest_client'
require 'capybara'
require 'selenium-webdriver'
require 'csv'

task :prices_for_set_cities => :environment do
  
  # San Fran

  get_prices("SFO SJC OAK", "JFK LGA EWR", "oneway")
  get_prices("SFO SJC OAK", "JFK LGA EWR", "return")

  get_prices("SFO SJC OAK", "LAX LGB", "oneway")
  get_prices("SFO SJC OAK", "LAX LGB", "return")

  get_prices("SFO SJC OAK", "ATL", "oneway")
  get_prices("SFO SJC OAK", "ATL", "return")

  get_prices("SFO SJC OAK", "ORD MDW", "oneway")
  get_prices("SFO SJC OAK", "ORD MDW", "return")

  get_prices("SFO SJC OAK", "IAD BWI DCA", "oneway")
  get_prices("SFO SJC OAK", "IAD BWI DCA", "return")

  get_prices("SFO SJC OAK", "DFW", "oneway")
  get_prices("SFO SJC OAK", "DFW", "return")

  get_prices("SFO SJC OAK", "SEA", "oneway")
  get_prices("SFO SJC OAK", "SEA", "return")

  get_prices("SFO SJC OAK", "BOS", "oneway")
  get_prices("SFO SJC OAK", "BOS", "return")

  get_prices("SFO SJC OAK", "LAS", "oneway")
  get_prices("SFO SJC OAK", "LAS", "return")

  get_prices("SFO SJC OAK", "HNL", "oneway")
  get_prices("SFO SJC OAK", "HNL", "return")

  get_prices("SFO SJC OAK", "SAN", "oneway")
  get_prices("SFO SJC OAK", "SAN", "return")

  get_prices("SFO SJC OAK", "DEN", "oneway")
  get_prices("SFO SJC OAK", "DEN", "return")

  # New York City

  # get_prices("JFK LGA EWR", "SFO SJC OAK", "oneway")
  # get_prices("JFK LGA EWR", "SFO SJC OAK", "return")

  # get_prices("JFK LGA EWR", "LAX LGB", "oneway")
  # get_prices("JFK LGA EWR", "LAX LGB", "return")

  # get_prices("JFK LGA EWR", "ATL", "oneway")
  # get_prices("JFK LGA EWR", "ATL", "return")

  # get_prices("JFK LGA EWR", "ORD MDW", "oneway")
  # get_prices("JFK LGA EWR", "ORD MDW", "return")

  # get_prices("JFK LGA EWR", "IAD BWI DCA", "oneway")
  # get_prices("JFK LGA EWR", "IAD BWI DCA", "return")

  # get_prices("JFK LGA EWR", "DFW", "oneway")
  # get_prices("JFK LGA EWR", "DFW", "return")

  # get_prices("JFK LGA EWR", "SEA", "oneway")
  # get_prices("JFK LGA EWR", "SEA", "return")

  # get_prices("JFK LGA EWR", "BOS", "oneway")
  # get_prices("JFK LGA EWR", "BOS", "return")

  # get_prices("JFK LGA EWR", "LAS", "oneway")
  # get_prices("JFK LGA EWR", "LAS", "return")

  # get_prices("JFK LGA EWR", "HNL", "oneway")
  # get_prices("JFK LGA EWR", "HNL", "return")

  # get_prices("JFK LGA EWR", "SAN", "oneway")
  # get_prices("JFK LGA EWR", "SAN", "return")
end

task :prices, [:origin_arr, :destination_arr, :type] => :environment do |t, args|
  get_prices(args.origin_arr, args.destination_arr, args.type)
end

def get_prices(origin_arr, destination_arr, type)
  Capybara.run_server = false
  Capybara.current_driver = :selenium
  Capybara.app_host = "https://www.google.com/flights"
  include Capybara::DSL

  if type == "oneway"
    param_variable = "tt=o;"
  else
    param_variable = "d=2014-02-10;r=2014-02-17;"
  end
  visit "/#search;f=#{origin_arr.gsub(' ', ',')};t=#{destination_arr.gsub(' ', ',')};#{param_variable}mc=p"
  sleep 2
  starting_num = 0
  CSV.open("db/prices/#{type}/#{origin_arr.gsub(' ', ',')}-#{destination_arr.gsub(' ', ',')}.csv", "wb") do |csv|
    csv << ["Days from today", "Price"]
    count = scrape_prices(csv, starting_num)
    click_next_month
    scrape_prices(csv, count)
  end

  if type == 'oneway'
    visit "https://www.google.com"
    visit "/#search;f=#{destination_arr.gsub(' ', ',')};t=#{origin_arr.gsub(' ', ',')};tt=o;mc=p"
    sleep 2
    starting_num = 0
    CSV.open("db/prices/#{type}/#{destination_arr.gsub(' ', ',')}-#{origin_arr.gsub(' ', ',')}.csv", "wb") do |csv|
      csv << ["Days from today", "Price"]
      count = scrape_prices(csv, starting_num)
      click_next_month
      scrape_prices(csv, count)
    end
  end
end

def scrape_prices(csv, starting_num)
  count = starting_num
  all(".GICUDSOHOC").each_with_index do |ele, i|
    ele.hover
    begin
      price = find('.GICUDSOPOC').text
      # puts "#{find('.GICUDSOOOC').text}: #{price}"
      csv << [count, price]
      count += 1
    rescue
      puts "Woah... error... gonna sleep for a bit then retry"
      sleep 5
      price = find('.GICUDSOPOC').text
      # puts "#{find('.GICUDSOOOC').text}: #{price}"
      csv << [count, price]
      count += 1
    end
  end
  return count
end

def click_next_month
  find(".GICUDSOJLC").click
  sleep 1
  find(".GICUDSOJLC").click
  sleep 2
end