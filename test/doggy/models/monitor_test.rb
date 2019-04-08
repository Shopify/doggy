# frozen_string_literal: true

require_relative '../../test_helper'

class Doggy::Models::DashboardTest < Minitest::Test
  def setup
    Doggy.stubs(:secrets).returns('datadog_api_key' => 'api_key_123', 'datadog_app_key' => 'app_key_345')
    Doggy.ui.stubs(:say)
  end

  def test_toggle_mute
    monitor = Doggy::Models::Monitor.new

    assert_nil(monitor.toggle_mute!('unmute'))

    monitor.id = 1
    assert_nil(monitor.toggle_mute!('something'))

    stub_request(:post, "https://app.datadoghq.com/api/v1/monitor/#{monitor.id}/mute?api_key=api_key_123&application_key=app_key_345")
      .to_return(status: 200, body: JSON.dump('errors' => 'already muted'))
    Doggy.ui.expects(:error).with('already muted')
    monitor.toggle_mute!('mute')
  end

  def test_mute
    fixture = load_fixture('monitor.json')
    monitor = Doggy::Models::Monitor.new(fixture)
    stub_request(:post, "https://app.datadoghq.com/api/v1/monitor/#{monitor.id}/mute?api_key=api_key_123&application_key=app_key_345")
      .to_return(status: 200, body: JSON.dump(fixture.merge(options: fixture['options'].merge('silenced' => { '*' => nil }))))
    monitor.expects(:save_local)
    monitor.toggle_mute!('mute')
    assert_equal(monitor.options.silenced, '*' => nil)
  end

  def test_unmute
    fixture = load_fixture('monitor.json')
    monitor = Doggy::Models::Monitor.new(fixture)
    stub_request(:post, "https://app.datadoghq.com/api/v1/monitor/#{monitor.id}/unmute?api_key=api_key_123&application_key=app_key_345")
      .to_return(status: 200, body: JSON.dump(fixture.merge(options: fixture['options'].merge('silenced' => {}))))
    monitor.expects(:save_local)
    monitor.toggle_mute!('unmute')
    assert_empty(monitor.options.silenced)
  end
end
