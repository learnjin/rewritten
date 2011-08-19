require 'rack'

module Rack

  class Filter

    def initialize(app)
      @app = app
    end

    def call(env)
      puts "-> Rack::Filter"
      req = Rack::Request.new(env)
      status, headers, response = @app.call(env)

      new_response = []
      
      response.each do |line|
        links = line.scan(/href="([^"]+)"/).uniq
        res = line
        links.each do |link|
          t = get_translation(link)
          res.gsub!(/#{link}/, t) if t
        end
        new_response << res
      end

      [status, headers, new_response]
    end

    private

    def get_translation(url)
      ::Rewritten.list_range("to:#{url}", -1, 1)
    end

  end

end



