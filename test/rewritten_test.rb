require 'rewritten'
require 'minitest/autorun'

describe Rewritten do

  before{
    Rewritten.clear_translations
  }

  it "must return all translations" do
    Rewritten.redis = :test unless ::Rewritten.redis == :test
    Rewritten.add_translation('/from', '/to')
    Rewritten.add_translation('/from2', '/to')
    Rewritten.add_translation('/from3', '/to2')

    expected = { "/to" => ['/from', '/from2'], "/to2" => ['/from3']}
    Rewritten.all_translations.must_equal expected
  end

end


