require_relative '../test_helper'

class Doggy::ModelTest < Minitest::Test
  class DummyModel < Doggy::Model
    attribute :id,    Integer
    attribute :title, String
  end

  class DummyModelWithRoot < DummyModel
    self.root = :dash
  end

  def test_save_local_ensures_read_only
    model = Doggy::Models::Monitor.new(id: 1, title: 'Some test', name: 'Monitor name', 'read_only' => false)
    File.expects(:open).with(Doggy.object_root.join('monitor-1.json'), 'w')
    model.save_local
    assert model.read_only
  end

  def test_create
    model = Doggy::Models::Dashboard.new({'dash' => {'title' => 'Pipeline', 'read_only' => true}})
    stub_request(:post, 'https://app.datadoghq.com/api/v1/dash?api_key=api_key_123&application_key=app_key_345').
        with(:body => "{\"description\":null,\"graphs\":[],\"id\":null,\"read_only\":true,\"template_variables\":[],\"title\":\"Pipeline 🐶\"}").
                      to_return(:status => 200, :body => "{\"id\":1}")
    File.expects(:open).with(Doggy.object_root.join('dash-1.json'), 'w')
    model.save
  end

  def test_update
    model = Doggy::Models::Monitor.new(id: 1, title: 'Some test', name: 'Monitor name', 'read_only' => true)
    stub_request(:put, "https://app.datadoghq.com/api/v1/monitor/1?api_key=api_key_123&application_key=app_key_345").
      with(:body => "{\"id\":1,\"message\":null,\"multi\":null,\"name\":\"Monitor name 🐶\",\"options\":{},"\
           "\"org_id\":null,\"query\":null,\"read_only\":true,\"tags\":[],\"type\":null}").
      to_return(:status => 200)
    model.save
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
