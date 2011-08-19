require 'rack'

module Rack

  class Dummy

    def call(env)
     puts "-> Rack::Dummy"
     lines = []
     req = Rack::Request.new(env)
     lines <<  req.path
     lines <<  req.params.inspect
     lines << '<a href="/some/resource">'
     [200, {"Content-Type"  => "text/plain"}, lines.join("\n")]
    end

  end

end



