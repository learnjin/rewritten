require 'rack'

module Rack
  class Dummy
    def call(env)
      puts '-> Rack::Dummy'
      lines = []
      req = Rack::Request.new(env)
      lines << req.path
      lines << req.params.inspect
      lines << req.host
      lines << req.env.inspect
      lines << "SUBDOMAIN: #{env['SUBDOMAIN']}"
      lines << '<a href="/some/resource">'
      [200, { 'Content-Type'  => 'text/plain' }, lines.join("\n")]
    end
  end
end
