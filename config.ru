require 'rack'
require 'rewritten'
require 'rewritten/server'
require 'pry'
require 'byebug'

map "/rewritten" do
  run Rewritten::Server
end

map "/" do
  use Rack::Rewritten::Url
  run Rack::Dummy.new
end

