require 'rack'

module Rack

  class Rewritten

    def initialize(app, options = {})
      @app = app
    end

    def call(env)
      puts "-> Rack::Rewritten"
      req = Rack::Request.new(env)

      if to = ::Rewritten.redis.get("from:#{req.path_info}")
        current_path = ::Rewritten.list_range("to:#{to}", -1, 1)  
        if current_path == req.path_info
          # if this is the current path, rewrite path and parameters
          tpath, tparams = split_to_path_params(to)
          req.path_info = tpath
          env['QUERY_STRING'] = Rack::Utils.build_query(tparams.merge(req.params))
          @app.call(req.env) 
        else
          # if this is not the current path, redirect to current path
          r = Rack::Response.new
          r.redirect(current_path, 301)
          r.finish
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



