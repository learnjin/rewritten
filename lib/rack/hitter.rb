require 'rack'

module Rack

  class Hitter

    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env.clone)
      status, headers, response = @app.call(env)
      puts "-> Rack::Hitter"
      puts headers.inspect

      if [200,301,302].include?(status)
        ::Rewritten.add_hit(req.path,status, headers["Content-Type"]) if headers["Content-Type"] =~ /text\/html/
      end

      [status, headers, response]
    end

  end

end





