require_relative '../test_helper'

class Doggy::ModelTest < Minitest::Test
  class DummyModel < Doggy::Model
    attribute :id,    Integer
    attribute :title, String
  end

  class DummyModelWithRoot < DummyModel
    self.root = 'dash'
  end

  def test_find_local
    dashboard = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    monitor= Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    monitor.path = File.join(Doggy.object_root, 'some-folder/monitor-22.json')
    screen = Doggy::Models::Screen.new(load_fixture('screen.json'))
    Doggy::Model.expects(:all_local_resources).times(6).returns([dashboard, monitor, screen])
    assert_equal dashboard, Doggy::Model.find_local(2473)
    assert_equal dashboard, Doggy::Model.find_local('2473')
    assert_equal dashboard, Doggy::Model.find_local('https://app.datadoghq.com/dash/2473')
    assert_equal monitor, Doggy::Model.find_local('https://app.datadoghq.com/monitors#22/edit')
    assert_equal monitor, Doggy::Model.find_local('objects/some-folder/monitor-22.json')
    assert_equal screen, Doggy::Model.find_local('https://app.datadoghq.com/screen/10/bbbb')
  end

  def test_save_local_ensures_read_only
    monitor = Doggy::Models::Monitor.new(id: 1, title: 'Some test', name: 'Monitor name', options: {locked: false})
    monitor.path = Tempfile.new('monitor-1.json').path
    monitor.save_local
    assert monitor.options.locked

    dashboard = Doggy::Models::Dashboard.new({'dash' => {'title' => 'Pipeline', 'read_only' => false}})
    dashboard.path = Tempfile.new('dash-1.json').path
    dashboard.save_local
    assert dashboard.read_only
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
    model = Doggy::Models::Monitor.new(id: 1, title: 'Some test', name: 'Monitor name')
    stub_request(:put, "https://app.datadoghq.com/api/v1/monitor/1?api_key=api_key_123&application_key=app_key_345").
      with(:body => "{\"id\":1,\"message\":null,\"multi\":null,\"name\":\"Monitor name 🐶\",\"options\":{},"\
           "\"org_id\":null,\"query\":null,\"tags\":[],\"type\":null}").
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
