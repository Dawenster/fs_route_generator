require 'rest_client'
# require 'capybara'
# require 'selenium-webdriver'
require 'csv'

task :prices_for_set_cities, [:stops] => :environment do |t, args|

  stops = args.stops
  
  # San Fran

  # get_prices("SFO SJC OAK", "JFK LGA EWR", "oneway", stops)
  get_prices("SFO SJC OAK", "JFK LGA EWR", "return", stops)

  get_prices("SFO SJC OAK", "LAX LGB", "oneway", stops)
  get_prices("SFO SJC OAK", "LAX LGB", "return", stops)

  get_prices("SFO SJC OAK", "ATL", "oneway", stops)
  get_prices("SFO SJC OAK", "ATL", "return", stops)

  get_prices("SFO SJC OAK", "ORD MDW", "oneway", stops)
  get_prices("SFO SJC OAK", "ORD MDW", "return", stops)

  get_prices("SFO SJC OAK", "IAD BWI DCA", "oneway", stops)
  get_prices("SFO SJC OAK", "IAD BWI DCA", "return", stops)

  get_prices("SFO SJC OAK", "DFW", "oneway", stops)
  get_prices("SFO SJC OAK", "DFW", "return", stops)

  get_prices("SFO SJC OAK", "SEA", "oneway", stops)
  get_prices("SFO SJC OAK", "SEA", "return", stops)

  get_prices("SFO SJC OAK", "BOS", "oneway", stops)
  get_prices("SFO SJC OAK", "BOS", "return", stops)

  get_prices("SFO SJC OAK", "LAS", "oneway", stops)
  get_prices("SFO SJC OAK", "LAS", "return", stops)

  get_prices("SFO SJC OAK", "HNL", "oneway", stops)
  get_prices("SFO SJC OAK", "HNL", "return", stops)

  get_prices("SFO SJC OAK", "SAN", "oneway", stops)
  get_prices("SFO SJC OAK", "SAN", "return", stops)

  get_prices("SFO SJC OAK", "DEN", "oneway", stops)
  get_prices("SFO SJC OAK", "DEN", "return", stops)

  # New York City

  # get_prices("JFK LGA EWR", "SFO SJC OAK", "oneway", stops)
  # get_prices("JFK LGA EWR", "SFO SJC OAK", "return", stops)

  # get_prices("JFK LGA EWR", "LAX LGB", "oneway", stops)
  # get_prices("JFK LGA EWR", "LAX LGB", "return", stops)

  # get_prices("JFK LGA EWR", "ATL", "oneway", stops)
  # get_prices("JFK LGA EWR", "ATL", "return", stops)

  # get_prices("JFK LGA EWR", "ORD MDW", "oneway", stops)
  # get_prices("JFK LGA EWR", "ORD MDW", "return", stops)

  # get_prices("JFK LGA EWR", "IAD BWI DCA", "oneway", stops)
  # get_prices("JFK LGA EWR", "IAD BWI DCA", "return", stops)

  # get_prices("JFK LGA EWR", "DFW", "oneway", stops)
  # get_prices("JFK LGA EWR", "DFW", "return", stops)

  # get_prices("JFK LGA EWR", "SEA", "oneway", stops)
  # get_prices("JFK LGA EWR", "SEA", "return", stops)

  # get_prices("JFK LGA EWR", "BOS", "oneway", stops)
  # get_prices("JFK LGA EWR", "BOS", "return", stops)

  # get_prices("JFK LGA EWR", "LAS", "oneway", stops)
  # get_prices("JFK LGA EWR", "LAS", "return", stops)

  # get_prices("JFK LGA EWR", "HNL", "oneway", stops)
  # get_prices("JFK LGA EWR", "HNL", "return", stops)

  # get_prices("JFK LGA EWR", "SAN", "oneway", stops)
  # get_prices("JFK LGA EWR", "SAN", "return", stops)
end

task :prices, [:origin_arr, :destination_arr, :type] => :environment do |t, args|
  get_prices(args.origin_arr, args.destination_arr, args.type)
end

def get_prices(origin_arr, destination_arr, type, stops)
  Capybara.run_server = false
  Capybara.current_driver = :selenium
  Capybara.app_host = "https://www.google.com/flights"
  include Capybara::DSL

  if type == "oneway"
    param_variable = "tt=o;"
  else
    param_variable = "d=2014-08-17;r=2014-08-24;"
  end

  visit "/?curr=USD#search;f=#{origin_arr.gsub(' ', ',')};t=#{destination_arr.gsub(' ', ',')};#{param_variable}mc=p;#{'s=' + stops if stops}"
  sleep 2
  starting_num = 0
  file_name = "#{type}/#{origin_arr.gsub(' ', ',')}-#{destination_arr.gsub(' ', ',')}"
  CSV.open("db/prices/#{file_name}.csv", "wb") do |csv|
    csv << ["Days from today", "Price"]
    count = scrape_prices(file_name, csv, starting_num)
    click_next_month
    scrape_prices(nil, csv, count)
  end

  if type == 'oneway'
    visit "https://www.google.com"
    visit "/?curr=USD#search;f=#{destination_arr.gsub(' ', ',')};t=#{origin_arr.gsub(' ', ',')};tt=o;mc=p;#{'s=' + stops if stops}"
    sleep 2
    starting_num = 0
    file_name = "#{type}/#{destination_arr.gsub(' ', ',')}-#{origin_arr.gsub(' ', ',')}"
    CSV.open("db/prices/#{file_name}.csv", "wb") do |csv|
      csv << ["Days from today", "Price"]
      count = scrape_prices(file_name, csv, starting_num)
      click_next_month
      scrape_prices(nil, csv, count)
    end
  end
end

def scrape_prices(file_name, csv, starting_num)
  count = starting_num
  puts file_name
  all(".GFYY1SVF0C").each_with_index do |ele, i|
    ele.hover
    begin
      price = find('.GFYY1SVN0C').text
      # puts "#{find('.GICUDSOOOC').text}: #{price}"
      csv << [count, price]
      count += 1
    rescue
      puts "Woah... error... gonna sleep for a bit then retry"
      sleep 5
      begin
        price = find('.GFYY1SVN0C').text
        # puts "#{find('.GICUDSOOOC').text}: #{price}"
        csv << [count, price]
        count += 1
      rescue
        puts "Nevermind... can't fix it.  SKIP!"
        count += 1
      end
    end
  end
  return count
end

def click_next_month
  find(".GFYY1SVKYC").click
  sleep 1
  find(".GFYY1SVKYC").click
  sleep 2
end