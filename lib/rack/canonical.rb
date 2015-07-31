require 'rack'

module Rack
  module Rewritten
    class Canonical
      def initialize(app)
        @app = app
      end

      def call(env)
        req = Rack::Request.new(env)

        status, headers, response = @app.call(req.env)

        if status == 200 && headers['Content-Type'] =~ /text\/html|application\/xhtml\+xml/
          body = ''
          response.each { |part| body << part }
          index = body.rindex('</head>')
          if index
            # go with a request duplicate since infinitive works on translations
            target_req = req.dup
            target_req.path_info = ::Rewritten.infinitive(::Rewritten.get_current_translation(req.path))
            target_req.env['QUERY_STRING'] = ''
            target = target_req.url

            body.insert(index, %(<link rel="canonical" href="#{target}"/>))
            headers['Content-Length'] = body.length.to_s
            response = [body]
          end

        end
        [status, headers, response]
      end
    end
  end
end
