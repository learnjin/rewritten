require 'rubygems'
require 'rack'
require 'rewritten'
require 'rewritten/server'

map "/" do
  use Rack::Rewritten
  #use Rack::Hitter
  use Rack::Filter
  run Rack::Dummy.new
end

map "/rewritten" do
  run Rewritten::Server
end


