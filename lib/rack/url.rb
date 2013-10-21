require 'rack'

module Rack

  module Rewritten

    class Url

      def initialize(app, &block)
        @app = app
        @translate_backwards = false
        @downcase_before_lookup = false
        @translate_partial = false

        instance_eval(&block) if block_given?
      end

      def call(env, tail=nil)
        req = Rack::Request.new(env)

        subdomain = env["SUBDOMAIN"] ? "#{env["SUBDOMAIN"]}:" : ""

        path = "#{subdomain}#{req.path_info}"
        path.downcase! if downcase_before_lookup?

        if ::Rewritten.includes?(path.chomp("/")) or translate_backwards? && ::Rewritten.exist_translation_for?(path) 

          to = ::Rewritten.includes?(path.chomp("/")) || path

          current_path = ::Rewritten.get_current_translation(to)
          current_path = current_path.split(":").last

          if current_path == req.path_info or ::Rewritten.has_flag?(path, 'L')
            # if this is the current path, rewrite path and parameters
            tpath, tparams = split_to_path_params(to)

            env['QUERY_STRING'] = Rack::Utils.build_query(tparams.merge(req.params))
            req.path_info = tpath + (tail ? "/"+tail : "")
            #@app.call(req.env)
            
            # add the canonical tag to the body
            status, headers, response = @app.call(req.env)

            if status == 200 && headers["Content-Type"] =~ /text\/html|application\/xhtml\+xml/
              body = ""
              response.each { |part| body << part }
              index = body.rindex("</head>")
              if index
                body.insert(index, %Q|<link rel="canonical" href="#{path}"/>| )
                headers["Content-Length"] = body.length.to_s
                response = [body]
              end
            end

            [status, headers, response]

          else
            # if this is not the current path, redirect to current path
            # NOTE: assuming redirection is always to non-subdomain-path

            r = Rack::Response.new

            new_path = env["rack.url_scheme"].dup
            new_path << "://"
            new_path << env["HTTP_HOST"].dup.sub(/^#{subdomain.chomp(':')}\./, '')
            new_path << current_path + (tail ? "/"+tail : "")
            new_path << '?' << env["QUERY_STRING"] unless (env["QUERY_STRING"]||'').empty?

            r.redirect(new_path, 301)
            a = r.finish
          end
        else
          # Translation of partials (e.g. /some/path/tail -> /translated/path/tail)
          if(path).count('/') > 1 && translate_partial?
            parts = path.split('/')
            req.path_info = parts.slice(0, parts.size-1).join('/')
            self.call(req.env, parts.last + (tail ? "/" + tail : ""))
          else
            req.path_info = (tail ? req.path_info+"/"+tail : req.path_info)
            @app.call(req.env)

          end
        end
      end

      def split_to_path_params(path_and_query)
        path, query_string = path_and_query.split('?').push('')[0..1]
        [path, Rack::Utils.parse_query(query_string)] 
      end


      private

      def translate_backwards?
        @translate_backwards
      end

      def translate_backwards=(yes_or_no)
        @translate_backwards = yes_or_no
      end

      def downcase_before_lookup?
        @downcase_before_lookup
      end

      def downcase_before_lookup=(yes_or_no)
        @downcase_before_lookup = yes_or_no
      end

      def translate_partial?
        @translate_partial
      end

      def translate_partial=(yes_or_no)
        @translate_partial = yes_or_no
      end
    end
  end
end
