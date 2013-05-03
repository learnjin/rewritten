require 'rewritten'
require 'rack/mock'
require 'minitest/autorun'
require 'pry'

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

  describe "redirection behavior" do

    before {
      @app = MiniTest::Mock.new

      @rack = Rack::Rewritten::Url.new(@app) do
        add_translation '/foo/bar', '/products/1'
        add_translation '/foo/baz', '/products/1'
        add_translation '/foo/with/params', '/products/2?w=1'
      end
    }

    it "must not redirect if there are no entries" do
      @app.expect :call, [200, {'Content-Type' => 'text/plain'},[""]], [Hash]
      @rack.call(call_args)
      @app.verify
    end

    it "must 301 redirect to latest translation" do
      ret = @rack.call( call_args.merge('REQUEST_URI' => '/foo/bar', 'PATH_INFO' => '/foo/bar' ))
      @app.verify
      ret[0].must_equal 301
      ret[1]['Location'].must_equal "http://www.example.org/foo/baz"
    end

    it "must stay on latest translation" do
      @app.expect :call, [200, {'Content-Type' => 'text/plain'},[""]], [Hash]
      ret = @rack.call( call_args.merge('REQUEST_URI' => '/foo/baz', 'PATH_INFO' => '/foo/baz' ))
      @app.verify
      ret[0].must_equal 200
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

