require 'rack'

module Rack
  module Rewritten
    class Url
      attr_accessor :base_url

      def initialize(app, &block)
        @app = app
        @translate_backwards = false
        @translate_backwards_exceptions = []
        @downcase_before_lookup = false
        @translate_partial = false
        @base_url = ''
        instance_eval(&block) if block_given?
      end

      def internal_target?(url)
        url.nil? || url.start_with?('/') || url.start_with?(@base_url)
      end

      def external_target?(url)
        !internal_target?(url)
      end

      def call(env)
        req = Rack::Request.new(env)

        subdomain = env['SUBDOMAIN'] ? "#{env['SUBDOMAIN']}:" : ''

        path = "#{subdomain}#{req.path_info}"
        path.downcase! if downcase_before_lookup

        target_url = ::Rewritten.translate(path)

        chomped_fullpath = req.fullpath.split('?').map { |s| s.chomp('/') }.join('?')

        if external_target?(target_url)
          r = Rack::Response.new
          r.redirect(target_url, 301)
          r.finish
        elsif ::Rewritten.includes?(chomped_fullpath) || ::Rewritten.includes?(path.chomp('/')) || backwards = (translate_backwards?(path) && ::Rewritten.exist_translation_for?(path))

          to = ::Rewritten.includes?(chomped_fullpath)
          to ||= ::Rewritten.includes?(path.chomp('/')) || path

          current_path = ::Rewritten.get_current_translation(to)
          current_path = current_path.split(':').last
          current_path_with_query = current_path
          current_path = current_path.split('?')[0]

          if current_path.size + 1 == req.path_info.size and current_path == req.path_info.chomp('/')
            r = Rack::Response.new

            new_path = env['rack.url_scheme'].dup
            new_path << '://'
            new_path << env['HTTP_HOST'].dup.sub(/^#{subdomain.chomp(':')}\./, '')
            new_path << current_path
            new_path << ::Rewritten.appendix(chomped_fullpath) unless backwards
            new_path << '?' << env['QUERY_STRING'] unless (env['QUERY_STRING'] || '').empty?

            r.redirect(new_path, 301)
            return r.finish
          end

          if (chomped_fullpath == current_path_with_query || current_path == req.path_info) || (::Rewritten.base_from(req.path_info) == current_path) || ::Rewritten.flag?(path, 'L')
            # if this is the current path, rewrite path and parameters
            tpath, tparams = split_to_path_params(to)
            env['QUERY_STRING'] = Rack::Utils.build_nested_query(tparams.merge(req.params))
            req.path_info = tpath + ::Rewritten.appendix(chomped_fullpath)
            @app.call(req.env)
          else
            # if this is not the current path, redirect to current path
            # NOTE: assuming redirection is always to non-subdomain-path

            r = Rack::Response.new

            new_path = env['rack.url_scheme'].dup
            new_path << '://'
            new_path << env['HTTP_HOST'].dup.sub(/^#{subdomain.chomp(':')}\./, '')
            new_path << current_path
            new_path << ::Rewritten.appendix(path) unless backwards
            new_path << '?' << env['QUERY_STRING'] unless (env['QUERY_STRING'] || '').empty?

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

      def translate_backwards?(path)
        return false unless @translate_backwards

        @translate_backwards_exceptions.each do |exception|
          return false if path.index(exception) == 0
        end

        true
      end

      attr_writer :translate_backwards
      attr_accessor :translate_backwards_exceptions
      attr_accessor :downcase_before_lookup

      def translate_partial=(yes_or_no)
        $stderr.puts 'DEPRECATED. Please use Rewritten.translate_partial'
        ::Rewritten.translate_partial = yes_or_no
      end
    end
  end
end
