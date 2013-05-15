require 'rack'

module Rack

  module Rewritten

    class Url

      def initialize(app, &block)
        @app = app
        @translate_backwards = false
        @downcase_before_lookup = false

        instance_eval(&block) if block_given?
      end

      def call(env)
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
            req.path_info = tpath
            env['QUERY_STRING'] = Rack::Utils.build_query(tparams.merge(req.params))
            @app.call(req.env) 
          else
            # if this is not the current path, redirect to current path
            # NOTE: assuming redirection is always to non-subdomain-path
            
            r = Rack::Response.new

            new_path = env["rack.url_scheme"].dup
            new_path << "://"
            new_path << env["HTTP_HOST"].dup.sub(/^#{subdomain.chomp(':')}\./, '')
            new_path << current_path
            new_path << '?' << env["QUERY_STRING"] unless (env["QUERY_STRING"]||'').empty?

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

      
    end
  end

end



