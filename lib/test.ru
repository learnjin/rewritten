require 'rubygems'
require 'rack'
require 'rewritten'
require 'rewritten/server'

map "/" do
  #use Rack::Rewritten::Record
  use Rack::Rewritten::Subdomain, "lvh.me"
  use Rack::Rewritten::Url
  use Rack::Rewritten::Html
  run Rack::Dummy.new
end

map "/rewritten" do
  run Rewritten::Server
end


