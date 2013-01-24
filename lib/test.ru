require_relative 'rewritten'
require_relative 'rewritten/server'

map "/" do
  #use Rack::Rewritten::Record
  use Rack::Rewritten::Subdomain, "doxter.de", "lvh.me"
  use Rack::Rewritten::Url
  use Rack::Rewritten::Html
  run Rack::Dummy.new
end

map "/rewritten" do
  run Rewritten::Server
end


