require 'test_helper'

describe Rewritten do
  before do
    Rewritten.add_translation('/from', '/to')
    Rewritten.add_translation('/from?w=1', '/to/w')
    Rewritten.add_translation('/from2', '/to')
    Rewritten.add_translation('/from3', '/to2')

    # with flags
    Rewritten.add_translation('/with/flags  [L12]', '/to3')
  end

  describe 'Rewritten.get_current_translation for to-target' do
    it 'must give current_translation' do
      Rewritten.get_current_translation('/to').must_equal '/from2'
      Rewritten.get_current_translation('/to2').must_equal '/from3'
      Rewritten.get_current_translation('/to3').must_equal '/with/flags'
      Rewritten.get_current_translation('/n/a').must_equal '/n/a'
    end

    it 'must find the translation if parameters are added' do
      Rewritten.add_translation('/from_without_params', '/to_without_params')
      Rewritten.get_current_translation('/to_without_params?some=param').must_equal '/from_without_params?some=param'
    end

    it 'must not add parameters twice if no translation is found' do
      Rewritten.get_current_translation('/no/translation?some=param').must_equal '/no/translation?some=param'
    end

    it 'must translate if protocol and host are given' do
      Rewritten.add_translation('/from_without_params', '/to_without_params')
      Rewritten.get_current_translation('http://localhost:3000/to_without_params').must_equal 'http://localhost:3000/from_without_params'
    end
  end

  describe 'get_infinitive (always from conjugated for -> for)' do
    it 'must work with nil' do
      Rewritten.infinitive(nil).must_equal ''
    end

    it 'must remove query parameters from non translatable foreign path' do
      Rewritten.infinitive('/no/translation').must_equal '/no/translation'
      Rewritten.infinitive('/no/translation/').must_equal '/no/translation'
      Rewritten.infinitive('/no/translation?some=param&another=2').must_equal '/no/translation'
    end

    it 'must remove query parameters from translatable foreign path' do
      Rewritten.infinitive('/from').must_equal '/from2'
      Rewritten.infinitive('/from/').must_equal '/from2'
      Rewritten.infinitive('/from?some=param&another=2').must_equal '/from2'
    end

    describe 'context translate partial' do
      before { Rewritten.translate_partial = true }
      after { Rewritten.translate_partial = false }

      it 'must remove trail if translpartial is enabled' do
        Rewritten.infinitive('/from/with/trail?and=param').must_equal '/from2'
      end
    end
  end

  describe 'basic interface' do
    it 'must translate froms' do
      Rewritten.translate('/from').must_equal '/to'
      Rewritten.translate('/from2').must_equal '/to'
      Rewritten.translate('/from3').must_equal '/to2'
      Rewritten.translate('/with/flags').must_equal '/to3'
      Rewritten.translate('/from?w=1').must_equal '/to/w'
    end

    it 'must return the  complete line with flags' do
      Rewritten.full_line('/from').must_equal '/from'
      Rewritten.full_line('/with/flags').must_equal '/with/flags [L12]'
    end

    it 'must give all tos' do
      Rewritten.all_tos.sort.must_equal ['/to', '/to/w', '/to2', '/to3']
    end
  end

  describe 'flag management' do
    it 'must return a flag string' do
      Rewritten.get_flag_string('/with/flags').must_equal 'L12'
      Rewritten.get_flag_string('/n/a').must_equal ''
    end

    it 'must query flags' do
      Rewritten.flag?('/with/flags', 'X').must_equal false
      Rewritten.flag?('/with/flags', 'L').must_equal true
      Rewritten.flag?('/with/flags', '1').must_equal true
      Rewritten.flag?('/with/flags', '2').must_equal true
    end
  end
end
