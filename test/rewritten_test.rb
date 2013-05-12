require 'rewritten'
require 'minitest/autorun'

describe Rewritten do

  before{
    Rewritten.redis = :test
    Rewritten.clear_translations
    Rewritten.add_translation('/from', '/to')
    Rewritten.add_translation('/from2', '/to')
    Rewritten.add_translation('/from3', '/to2')
  }

  it "must give all tos" do
    Rewritten.all_tos.must_equal ["/to", "/to2"] 
  end

  it "must return all translations" do
    expected = { "/to" => ['/from', '/from2'], "/to2" => ['/from3']}
    Rewritten.all_translations.must_equal expected
  end

end


