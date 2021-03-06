require 'test_helper'

describe Rack::Rewritten::Url do
  def call_args(overrides = {})
    { 'HTTP_HOST' => 'www.example.org',
      'REQUEST_URI' => '/foo/with/params',
      'SCRIPT_INFO' => '',
      'PATH_INFO' => '/foo/with/params',
      'QUERY_STRING' => '',
      'SERVER_PORT' => 80,
      'rack.input' => '',
      'rack.url_scheme' => 'http' }.merge(overrides)
  end

  def request_url(url, params = {})
    call_args.merge({ 'REQUEST_URI' => url, 'PATH_INFO' => url }.merge(params))
  end

  before do
    Rewritten.add_translation '/foo/bar', '/products/1'
    Rewritten.add_translation '/foo/baz', '/products/1'
    Rewritten.add_translation '/foo/with/params', '/products/2?w=1'
    Rewritten.add_translation '/foo/with/params?w=1', '/embed/2'
  end

  describe 'redirection behavior' do
    before do
      @app = MiniTest::Mock.new
      @rack = Rack::Rewritten::Url.new(@app)

      Rewritten.add_translation '/foo/bar', '/products/1'
      Rewritten.add_translation '/foo/baz', '/products/1'
      Rewritten.add_translation '/foo/with/params', '/products/2?w=1'
    end

    it 'must not redirect if there are no entries' do
      @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]
      @rack.call(call_args)
      @app.verify
    end

    it 'must 301 redirect from old translation to latest translation' do
      ret = @rack.call request_url('/foo/bar')
      @app.verify
      ret[0].must_equal 301
      ret[1]['Location'].must_equal 'http://www.example.org/foo/baz'
    end

    it 'must keep the query parameters in the 301 redirect' do
      ret = @rack.call request_url('/foo/bar', 'QUERY_STRING' => 'w=1')
      @app.verify
      ret[0].must_equal 301
      ret[1]['Location'].must_equal 'http://www.example.org/foo/baz?w=1'
    end

    it 'must stay on latest translation' do
      @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]
      ret = @rack.call request_url('/foo/baz')
      @app.verify
      ret[0].must_equal 200
    end

    describe 'external redirection' do
      before do
        @app = MiniTest::Mock.new
        @rack = Rack::Rewritten::Url.new(@app) do |config|
          config.base_url = 'http://www.example.org'
        end

        Rewritten.add_translation '/external/target', 'http://www.external.com'
      end

      it 'must redirect to external target' do
        ret = @rack.call request_url('/external/target')
        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal 'http://www.external.com'
      end
    end

    describe 'partial translation' do
      before do
        @request_str = '/foo/baz/with_tail'
        @env = request_url(@request_str)
        Rewritten.translate_partial = true
      end

      after do
        Rewritten.translate_partial = false
      end

      after { Rewritten.translate_partial = false }

      it 'must not translate partials by default' do
        Rewritten.translate_partial = false
        @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]
        @rack.call @env
        @app.verify
        @env['PATH_INFO'].must_equal @request_str
      end

      it 'must translate partials if enabled' do
        Rewritten.translate_partial = true
        @app.expect :call, [200, { 'Content-Type' => 'text/html' }, []], [Hash]
        @rack.call @env
        @app.verify
        @env['PATH_INFO'].must_equal '/products/1/with_tail'
      end

      it 'must work on long, non-translated urls with partial translation enabled' do
        @app.expect :call, [200, { 'Content-Type' => 'text/html' }, []], [Hash]

        url = '/such/a/long/url/with/so/many/slashes/oh/my/god'
        @env = request_url(url)

        @rack.call @env
        @app.verify
        @env['PATH_INFO'].must_equal url
      end

      it "won't translate segments not by separated by slashes" do
        @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]
        @rack.call @env = request_url('/foo/bazzling')
        @app.verify
        @env['PATH_INFO'].must_equal '/foo/bazzling'
      end

      it 'must carry on trail when redirecting' do
        ret = @rack.call request_url('/foo/bar/with_tail', 'QUERY_STRING' => 'w=1')
        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal 'http://www.example.org/foo/baz/with_tail?w=1'
      end
    end

    describe '/ behavior' do
      it 'must 301 redirect current paths with / in the end to their chomped version' do
        ret = @rack.call request_url('/foo/baz/')
        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal 'http://www.example.org/foo/baz'
      end

      it 'must 301 redirect current paths with / before the query string to their chomped version' do
        Rewritten.add_translation '/path/with/params?w=1', '/embed/2'
        ret = @rack.call request_url('/path/with/params/', 'QUERY_STRING' => 'w=1')
        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal 'http://www.example.org/path/with/params?w=1'
      end

      it 'wont 301 redirect /' do
        @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]
        ret = @rack.call request_url('/')
        @app.verify
      end

      it 'must 301 redirect non-current paths with / in the end to their current chomped version' do
        ret = @rack.call request_url('/foo/bar/')
        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal 'http://www.example.org/foo/baz'
      end
    end

    describe 'caps behavior' do
      it 'must diferentiate caps' do
        @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]
        ret = @rack.call request_url('/Foo/Bar')
        @app.verify
        ret[0].must_equal 200
      end

      it 'must ignore caps if wished' do
        @rack = Rack::Rewritten::Url.new(@app) do
          self.downcase_before_lookup = true
        end

        ret = @rack.call request_url('/Foo/Bar')

        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal 'http://www.example.org/foo/baz'
      end
    end

    describe 'enforce nice urls' do
      it 'must not redirect from resource url to nice url by default' do
        @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]
        ret = @rack.call request_url('/products/1')
        @app.verify
        ret[0].must_equal 200
      end

      it 'must redirect from resource url to nice url if enabled' do
        @rack = Rack::Rewritten::Url.new(@app) do
          self.translate_backwards = true
        end

        ret = @rack.call request_url('/products/1')
        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal 'http://www.example.org/foo/baz'
      end

      it 'must not redirect from resource url to nice url if enabled but in exceptions' do
        @rack = Rack::Rewritten::Url.new(@app) do
          self.translate_backwards = true
          self.translate_backwards_exceptions = ['/products']
        end

        @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]
        ret = @rack.call request_url('/products/1')
        @app.verify
        ret[0].must_equal 200
      end
    end

    describe 'flag behavior' do
      before do
        Rewritten.add_translation('/with/flags [L]', '/adwords/target')
        Rewritten.add_translation('/with/flags2 [L]', '/adwords/target')
        Rewritten.add_translation('/no/flags', '/adwords/target')
        Rewritten.add_translation('/final/line', '/adwords/target')
      end

      it 'must stay on [L] flagged froms' do
        @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]
        @app.expect :call, [200, { 'Content-Type' => 'text/plain' }, ['']], [Hash]

        ret = @rack.call(request_url('/with/flags'))
        ret[0].must_equal 200

        ret = @rack.call(request_url('/with/flags2'))
        ret[0].must_equal 200

        @app.verify
      end

      it 'must redirect for other entries' do
        ret = @rack.call request_url('/no/flags')
        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal 'http://www.example.org/final/line'
      end
    end
  end

  describe 'the env' do
    before do
      @initial_args = call_args.dup
      @rack = Rack::Rewritten::Url.new(->(_env) { [200, {}, ['']] })
    end

    it 'must set PATH_INFO to /products/2' do
      @rack.call(@initial_args)
      @initial_args['PATH_INFO'].must_equal '/products/2'
    end

    it 'must set QUERY_STRING to w=1' do
      @rack.call(@initial_args)
      @initial_args['QUERY_STRING'].must_equal 'w=1'
    end

    it 'must merge QUERY parameters' do
      @initial_args.merge!('QUERY_STRING' => 's=1')
      @rack.call(@initial_args)
      @initial_args['QUERY_STRING'].split('&').sort.must_equal ['s=1', 'w=1']
    end

    it 'must merge nested rails style QUERY parameters' do
      @initial_args.merge!('QUERY_STRING' => 'x[id]=1')
      @rack.call(@initial_args)
      @initial_args['QUERY_STRING'].split('&').sort.map { |s| URI.unescape(s) }.must_equal ['w=1', 'x[id]=1']
    end

    it 'must discriminate between explicit query string translations' do
      @initial_args.merge!('QUERY_STRING' => 'w=1')
      @rack.call(@initial_args)
      @initial_args['PATH_INFO'].must_equal '/embed/2'
    end

    it 'must translate if the only translation is a parameter translation' do
      Rewritten.add_translation '/foo/two/params?w=1', '/embed/2'
      @initial_args.merge!('QUERY_STRING' => 'w=1', 'REQUEST_URI' => '/foo/two/params', 'PATH_INFO' => '/foo/two/params')
      @rack.call(@initial_args)
      @initial_args['PATH_INFO'].must_equal '/embed/2'
    end

    it 'must be possible to pass extra parameters not in translation' do
      Rewritten.add_translation '/foo/without/params', '/embed/2'
      @initial_args.merge!('QUERY_STRING' => 'w=1', 'REQUEST_URI' => '/foo/without/params', 'PATH_INFO' => '/foo/without/params')
      @rack.call(@initial_args)
      @initial_args['PATH_INFO'].must_equal '/embed/2'
      @initial_args['QUERY_STRING'].must_equal 'w=1'
    end
  end
end
