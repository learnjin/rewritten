require 'rewritten'
require 'minitest/autorun'
require 'pry'
require 'coveralls'

Coveralls.wear!

class Minitest::Spec
  before :each do
    Rewritten.redis = 'localhost:6379/test_rewritten'
    Rewritten.clear_translations
  end

  after :each do
    Rewritten.clear_translations
  end
end
