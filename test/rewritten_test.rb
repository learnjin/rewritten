require 'test_helper'

describe Rewritten do

  before{
    Rewritten.add_translation('/from', '/to')
    Rewritten.add_translation('/from2', '/to')
    Rewritten.add_translation('/from3', '/to2')
  }

  it "must give all tos" do
    Rewritten.all_tos.sort.must_equal ["/to", "/to2"] 
  end

  it "must return all translations" do
    expected = { "/to" => ['/from', '/from2'], "/to2" => ['/from3']}
    Rewritten.all_translations.must_equal expected
  end

end


