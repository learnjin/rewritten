require 'test_helper'

describe Rack::Rewritten::Url do

  def call_args(overrides={})
    {'HTTP_HOST' => 'www.example.org',
      'REQUEST_URI' => '/foo/with/params',
      'SCRIPT_INFO'=> '',
      'PATH_INFO' => '/foo/with/params',
      'QUERY_STRING' => '',
      'rack.input' => '',
      'rack.url_scheme' => 'http'}.merge(overrides)
  end
  
  def request_url(url)
    call_args.merge('REQUEST_URI' => url, 'PATH_INFO' => url )
  end

  before {
    Rewritten.add_translation '/foo/bar', '/products/1'
    Rewritten.add_translation '/foo/baz', '/products/1'
    Rewritten.add_translation '/foo/with/params', '/products/2?w=1'
  }

  describe "redirection behavior" do

    before {
      @app = MiniTest::Mock.new
      @rack = Rack::Rewritten::Url.new(@app)

      Rewritten.add_translation '/foo/bar', '/products/1'
      Rewritten.add_translation '/foo/baz', '/products/1'
      Rewritten.add_translation '/foo/with/params', '/products/2?w=1'
    }

    it "must not redirect if there are no entries" do
      @app.expect :call, [200, {'Content-Type' => 'text/plain'},[""]], [Hash]
      @rack.call(call_args)
      @app.verify
    end

    it "must 301 redirect from old translation to latest translation" do
      ret = @rack.call( call_args.merge('REQUEST_URI' => '/foo/bar', 'PATH_INFO' => '/foo/bar' ))
      @app.verify
      ret[0].must_equal 301
      ret[1]['Location'].must_equal "http://www.example.org/foo/baz"
    end

    it "must keep the query parameters in the 301 redirect" do
      ret = @rack.call( call_args.merge('REQUEST_URI' => '/foo/bar', 'PATH_INFO' => '/foo/bar', 'QUERY_STRING' => 'w=1' ))
      @app.verify
      ret[0].must_equal 301
      ret[1]['Location'].must_equal "http://www.example.org/foo/baz?w=1"
    end

    it "must stay on latest translation" do
      @app.expect :call, [200, {'Content-Type' => 'text/plain'},[""]], [Hash]
      ret = @rack.call( call_args.merge('REQUEST_URI' => '/foo/baz', 'PATH_INFO' => '/foo/baz' ))
      @app.verify
      ret[0].must_equal 200
    end

    describe "enforce nice urls" do

      it "must not redirect from resource url to nice url by default" do
        @app.expect :call, [200, {'Content-Type' => 'text/plain'},[""]], [Hash]
        ret = @rack.call( call_args.merge('REQUEST_URI' => '/products/1', 'PATH_INFO' => '/products/1' ))
        @app.verify
        ret[0].must_equal 200
      end

      it "must redirect from resource url to nice url if enabled xxx" do
        @rack = Rack::Rewritten::Url.new(@app) do
          self.translate_backwards = true
        end

        ret = @rack.call( call_args.merge('REQUEST_URI' => '/products/1', 'PATH_INFO' => '/products/1' ))
        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal "http://www.example.org/foo/baz"
      end

    end

    describe "flag behavior" do

      before {
        Rewritten.add_translation('/with/flags [L]', '/adwords/target')
        Rewritten.add_translation('/with/flags2 [L]', '/adwords/target')
        Rewritten.add_translation('/no/flags', '/adwords/target')
        Rewritten.add_translation('/final/line', '/adwords/target')
      }

      it "must stay on [L] flagged froms" do
        @app.expect :call, [200, {'Content-Type' => 'text/plain'},[""]], [Hash]
        @app.expect :call, [200, {'Content-Type' => 'text/plain'},[""]], [Hash]

        ret = @rack.call( request_url('/with/flags'))
        ret[0].must_equal 200

        ret = @rack.call( request_url('/with/flags2'))
        ret[0].must_equal 200

        @app.verify
      end

      it "must redirect for other entries" do
        ret = @rack.call( request_url('/no/flags') )
        @app.verify
        ret[0].must_equal 301
        ret[1]['Location'].must_equal "http://www.example.org/final/line"
      end

    end


  end



  describe "the env" do

    before {
      @initial_args = call_args.dup
      @rack = Rack::Rewritten::Url.new(lambda{|env| [200, {}, [""]]})
    }

    it "must set PATH_INFO to /products/2" do
      @rack.call(@initial_args)
      @initial_args['PATH_INFO'].must_equal "/products/2" 
    end

    it "must set QUERY_STRING to w=1" do
      @rack.call(@initial_args)
      @initial_args['QUERY_STRING'].must_equal 'w=1'
    end

    it "must merge QUERY parameters" do
      @initial_args.merge!('QUERY_STRING' => 's=1')
      @rack.call(@initial_args)
      @initial_args['QUERY_STRING'].split('&').sort.must_equal ['s=1', 'w=1']
    end

  end



end

