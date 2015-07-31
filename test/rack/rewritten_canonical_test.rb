require 'test_helper'

describe Rack::Rewritten::Canonical do
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

    @html_body = <<-HTML
    <html>
      <head></head>
      <body>Hello</body>
    </html>
    HTML
    @rack = Rack::Rewritten::Canonical.new(->(_env) { [200, { 'Content-Type' => 'text/html' }, [@html_body]] })
  end

  describe 'canonical tag' do
    it 'must add the canonical tag to current translation if on non-translated page' do
      _res, _env, body = @rack.call request_url('/products/1')
      html = body.join('')
      html.must_include '<link rel="canonical" href="http://www.example.org/foo/baz"/>'
    end

    it 'the target of the canonical tag must have no params' do
      _res, _env, body = @rack.call request_url('/products/1').merge('QUERY_STRING' => 'some=param')
      html = body.join('')
      html.must_include '<link rel="canonical" href="http://www.example.org/foo/baz"/>'
    end

    describe 'context partial' do
      before { Rewritten.translate_partial = true }
      after { Rewritten.translate_partial = false }

      it 'must add the canonical tag to pages with tail' do
        _res, _env, body = @rack.call request_url('/products/1/with/tail')
        html = body.join('')
        html.must_include '<link rel="canonical" href="http://www.example.org/foo/baz"/>'
      end
    end
  end
end
