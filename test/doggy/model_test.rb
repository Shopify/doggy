require_relative '../test_helper'

class Doggy::ModelTest < Minitest::Test
  class DummyModel < Doggy::Model
    attribute :id,    Integer
    attribute :title, String
  end

  class DummyModelWithRoot < DummyModel
    self.root = :dash
  end

  def test_sort_by_key
    h = { b: [ {d: 1, a: 2}, {x: 1, p: 3, y: 5} ], a: 3 }
    expected = { a: 3, b: [ {a: 2, d: 1}, {p: 3, x: 1, y: 5} ] }
    assert_equal Doggy::Model.sort_by_key(h).to_s, expected.to_s
  end

  def test_mass_assignment
    instance = DummyModel.new(id: 1, title: 'Some test')

    assert_equal 1,           instance.id
    assert_equal 'Some test', instance.title
  end

  def test_value_coallescion
    instance = DummyModel.new(id: '2', title: :a_symbol)

    assert_equal 2,          instance.id
    assert_equal 'a_symbol', instance.title
  end

  def test_root
    first_instance  = DummyModelWithRoot.new({'dash' => {'id' => 1, 'title' => 'Pipeline'}})
    second_instance = DummyModelWithRoot.new(id: 2, title: 'RPMs')

    assert_equal 1,          first_instance.id
    assert_equal 'Pipeline', first_instance.title

    assert_equal 2,      second_instance.id
    assert_equal 'RPMs', second_instance.title
  end

  def test_type_inferrence
    assert_equal Doggy::Models::Dashboard, Doggy::Model.infer_type({'graphs'      => []})
    assert_equal Doggy::Models::Monitor,   Doggy::Model.infer_type({'message'     => ''})
    assert_equal Doggy::Models::Screen,    Doggy::Model.infer_type({'board_title' => ''})
  end
end
