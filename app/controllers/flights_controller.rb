require 'csv'

class FlightsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def routes_to_scrape
    respond_to do |format|
      if params[:password] == ENV['POST_PASSWORD']
        routes = []
        Dir[Rails.root.join("db/routes/#{params[:code]}/*.csv")].each do |file|
          CSV.foreach(file) do |route|
            routes << [route[0], route[1]]
          end
        end
        format.json { render :json => { "routes" => routes.uniq } }
      else
        format.json { render :json => { "message" => "Whatcha tryin' to pull?" } }
      end
    end
  end
end