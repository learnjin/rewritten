require 'rubygems'
require 'rack'
require "../lib/rack/dummy"

run Rack::Dummy.new

