require_relative '../../test_helper'

class Doggy::CLI::PushTest < Minitest::Test
  def test_push_ensures_read_only
    resource = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    Doggy::Models::Dashboard.expects(:all_local).returns([resource])
    Doggy::Models::Monitor.expects(:all_local).returns([])
    Doggy::Models::Screen.expects(:all_local).returns([])
    stub_request(:put, "https://app.datadoghq.com/api/v1/dash/#{resource.id}?api_key=api_key_123&application_key=app_key_345").
      with(body: JSON.dump(resource.to_h.merge(read_only: true, title: resource.title + " \xF0\x9F\x90\xB6")))
      .to_return(status: 200)

    Doggy::CLI::Push.new({'dashboards' => true, 'monitors' => true, 'screens' => true}, []).run
  end

  def test_push_by_ids
    screen = Doggy::Models::Screen.new(load_fixture('screen.json'))
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    Doggy::Models::Dashboard.expects(:all_local).returns([])
    Doggy::Models::Monitor.expects(:all_local).returns([monitor])
    Doggy::Models::Screen.expects(:all_local).returns([screen])
    stub_request(:put, "https://app.datadoghq.com/api/v1/#{screen.prefix}/#{screen.id}?api_key=api_key_123&application_key=app_key_345").
      with(body: JSON.dump(Doggy::Model.sort_by_key(screen.to_h.merge(read_only: true, board_title: screen.board_title + " \xF0\x9F\x90\xB6")))).
      to_return(status: 200)
    stub_request(:put, "https://app.datadoghq.com/api/v1/#{monitor.prefix}/#{monitor.id}?api_key=api_key_123&application_key=app_key_345").
      with(body: JSON.dump(Doggy::Model.sort_by_key(monitor.to_h.merge(options: monitor.options.to_h.merge(locked: true), name: monitor.name + " \xF0\x9F\x90\xB6")))).
      to_return(status: 200)

    Doggy::CLI::Push.new({}, [screen.id.to_s, monitor.id.to_s]).run
  end
end
