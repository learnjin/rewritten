require 'rack'

module Rack

  module Rewritten

    class Url

      def initialize(app, options = {})
        @app = app
      end

      def call(env)
        req = Rack::Request.new(env)

        subdomain = env["SUBDOMAIN"] ? "#{env["SUBDOMAIN"]}:" : ""

        if to = ::Rewritten.redis.get("from:#{subdomain}#{req.path_info}")
          current_path = ::Rewritten.list_range("to:#{to}", -1, 1)  
          current_path = current_path.split(":").last
          if current_path == req.path_info
            # if this is the current path, rewrite path and parameters
            tpath, tparams = split_to_path_params(to)
            req.path_info = tpath
            env['QUERY_STRING'] = Rack::Utils.build_query(tparams.merge(req.params))
            @app.call(req.env) 
          else
            # if this is not the current path, redirect to current path
            r = Rack::Response.new
            # NOTE: assuming redirection is always to non-subdomain-path
            
            new_path = env["rack.url_scheme"].dup
            new_path << "://"
            new_path << env["HTTP_HOST"].dup.sub(/^#{subdomain.chomp(':')}\./, '')
            new_path << current_path

            r.redirect(new_path, 301)
            a = r.finish
          end
        else
          @app.call(req.env) 
        end
      end

      def split_to_path_params(path_and_query)
        path, query_string = path_and_query.split('?').push('')[0..1]
        [path, Rack::Utils.parse_query(query_string)] 
      end

    end
  end

end



