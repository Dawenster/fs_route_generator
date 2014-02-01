require 'rest_client'
require 'capybara'
require 'selenium-webdriver'
require 'csv'

task :prices, [:origin_arr, :destination_code, :type] => :environment do |t, args|
  # result = RestClient.get "https://www.google.com/flights/#search;f=#{args.origin_arr.gsub(' ', ',')};t=#{args.destination_code};tt=o;mc=p"

  Capybara.run_server = false
  Capybara.current_driver = :selenium
  Capybara.app_host = "https://www.google.com/flights"
  include Capybara::DSL

  visit "/#search;f=#{args.origin_arr.gsub(' ', ',')};t=#{args.destination_code};#{'tt=o;' if args.type == 'oneway'}mc=p"
  sleep 2
  starting_num = 0
  CSV.open("db/prices/#{args.type}/#{args.origin_arr.gsub(' ', ',')}-#{args.destination_code}.csv", "wb") do |csv|
    csv << ["Days from today", "Price"]
    count = scrape_prices(csv, starting_num)
    click_next_month
    scrape_prices(csv, count)
  end

  if args.type == 'oneway'
    visit "https://www.google.com"
    visit "/#search;f=#{args.destination_code};t=#{args.origin_arr.gsub(' ', ',')};tt=o;mc=p"
    sleep 2
    starting_num = 0
    CSV.open("db/prices/#{args.type}/#{args.destination_code}-#{args.origin_arr.gsub(' ', ',')}.csv", "wb") do |csv|
      csv << ["Days from today", "Price"]
      count = scrape_prices(csv, starting_num)
      click_next_month
      scrape_prices(csv, count)
    end
  end
end

def scrape_prices(csv, starting_num)
  count = starting_num
  all(".GAJ4KBDCENC").each_with_index do |ele, i|
    ele.hover
    puts "#{find('.GAJ4KBDCLNC').text}: #{find('.GAJ4KBDCMNC').text}"
    csv << [count, find(".GAJ4KBDCMNC").text]
    count += 1
  end
  return count
end

def click_next_month
  find(".GAJ4KBDCGKC").click
  sleep 1
  find(".GAJ4KBDCGKC").click
  sleep 2
end