require 'rack'

module Rack

  module Rewritten

    class Html

      def initialize(app)
        @app = app
      end

      def call(env)
        req = Rack::Request.new(env)
        status, headers, response = @app.call(env)

        if status == 200
          new_response = []
          response.each do |line|
            links = line.scan(/href="([^"]+)"/).flatten.uniq
            res = line
            links.each do |link|
              t = ::Rewritten.get_current_translation(link)
              res.gsub!(/href="#{link}"/, %Q|href="#{t}"|) if t
            end
            new_response << res
          end
        else
          new_response = response
        end

        [status, headers, new_response]
      end

    end

  end
end


