require 'test_helper'

describe Rewritten::Document do

  before do
    class Product
      include Rewritten::Document
    end
    @instance = Product.new
    def @instance.id; 123; end
    def @instance.polymorphic_url(object, options={}); "/products/#{self.id}"; end
    def @instance.persisted?; true; end
  end

  it 'must add the rewritten methods to the class' do
    @instance.respond_to?(:rewritten_url=).must_equal true
    @instance.respond_to?(:rewritten_url).must_equal true
    @instance.respond_to?(:has_rewritten_url?).must_equal true
  end

  it 'must return empty string when not persisted' do

    def @instance.persisted?; false; end

    @instance.rewritten_url.must_equal "" 
  end

  describe 'add translation' do

    describe 'url_for not overriden' do
      it 'must return translation when persisted' do
        Rewritten.add_translation('/foo/bar', '/products/123') 
        @instance.rewritten_url.must_equal '/foo/bar'
      end
    end

    describe 'url_to overriden' do
      it 'must return translation when persisted' do
        Rewritten.add_translation('/foo/bar', '/products/123') 
        def @instance.polymorphic_url(object, options={}); '/foo/bar'; end
        Rewritten.translate(@instance.rewritten_url).must_equal '/products/123'
      end
    end

  end

  it 'must return all translations as array' do

    Rewritten.add_translation('/foo/bar', '/products/123')
    Rewritten.add_translation('/foo/baz', '/products/123')

    @instance.rewritten_urls.must_equal ['/foo/bar', '/foo/baz']         
  end

  it 'must add a new translation' do
    @instance.has_rewritten_url?.must_equal false
    @instance.rewritten_url = '/foo/baz'  
    Rewritten.get_current_translation('/products/123').must_equal '/foo/baz'
    @instance.has_rewritten_url?.must_equal true
  end

  it 'must remove all translation' do
    @instance.rewritten_url = '/foo/bar'  
    @instance.rewritten_url = '/foo/baz'  
    @instance.remove_rewritten_urls
    @instance.rewritten_urls.must_equal []
  end

  it 'must won\'t add blank and similar translations' do
    @instance.rewritten_url = '/foo/bar'  
    @instance.rewritten_urls.must_equal ['/foo/bar']
    @instance.rewritten_url = nil
    @instance.rewritten_urls.must_equal ['/foo/bar']
    @instance.rewritten_url = ""
    @instance.rewritten_urls.must_equal ['/foo/bar']
    @instance.rewritten_url = "/foo/bar"
    @instance.rewritten_urls.must_equal ['/foo/bar']
  end

end




