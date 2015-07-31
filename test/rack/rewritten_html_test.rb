require 'test_helper'

describe Rack::Rewritten::Url do
  before do
    Rewritten.add_translation '/foo/bar', '/products/1'
    Rewritten.add_translation '/foo/baz', '/products/1'
    Rewritten.add_translation '/foo/with/params', '/products/2?w=1'
  end

  describe 'substition behavior' do
    before do
      @html_body = <<-HTML
      <html>
        <body>
        <a href="/">home</a>
        <a href="/foo">foo</a>
        <a href="/foo?d=1">foo</a>
        <a href='/foo?s=1'>foo</a>
        <a href='/foolmenot'>fool</a>
        <a href="#">nolink</a>
        <a href="/bookings/new?booking[starts]=1371623400&amp;booking[ends]=1371624300&amp;booking[calendar_id]=50ed77ffed284b0002000008&amp;booking[problem_id]=4d7dfc412696e7790f00002d&amp;booking[service_ids][]=50ed77ffed284b000200000f&amp;insurance=public">time</a>
        </body>
      </html>
      HTML

      @rack = Rack::Rewritten::Html.new(->(_env) { [200, {}, [@html_body]] })
    end

    it 'must ignore everything' do
      _res, _env, body = @rack.call({})
      html = body.join('')
      html.must_equal @html_body
    end

    it 'must replace links with translations' do
      Rewritten.add_translation('/bar', '/foo')
      _res, _env, body = @rack.call({})
      html = body.join('')
      assert ! (html =~ (/foo\??["']/)), "didn't replace all /foo links"
      assert html.include? '/bar'
      assert html.include?('/foolmenot'), 'must not mess with similar links'
    end
  end
end
