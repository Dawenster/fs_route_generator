FsRouteGenerator::Application.routes.draw do
  get "routes-to-scrape" => "flights#routes_to_scrape", :as => :routes_to_scrape
end
