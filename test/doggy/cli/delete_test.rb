require_relative '../../test_helper'

class Doggy::CLI::DeleteTest < Minitest::Test
  def test_run
    screen = Doggy::Models::Screen.new(load_fixture('screen.json'))
    screen.path = Tempfile.new("#{screen.prefix}-#{screen.id}.json").path
    stub_request(:delete, "https://app.datadoghq.com/api/v1/#{screen.prefix}/#{screen.id}?api_key=api_key_123&application_key=app_key_345").
      to_return(status: 200, body: JSON.dump("deleted_#{screen.class.name.split('::').last.downcase}_id" => screen.id))
    File.expects(:delete).with(screen.path)

    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    stub_request(:delete, "https://app.datadoghq.com/api/v1/#{monitor.prefix}/#{monitor.id}?api_key=api_key_123&application_key=app_key_345").
      to_return(status: 200, body: JSON.dump(errors: 'Could not find the monitor'))
    Doggy.ui.expects(:error)

    Doggy::Model.expects(:all_local_resources).returns([screen, monitor])

    Doggy::CLI::Delete.new.run([screen.id.to_s, monitor.id.to_s])
  end

  def test_run_when_remote_destroy_fails
    screen = Doggy::Models::Screen.new(load_fixture('screen.json'))
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    Doggy::Model.expects(:all_local_resources).returns([screen, monitor])
    [screen, monitor].each do |resource|
      resource.path = Tempfile.new("#{resource.prefix}-#{resource.id}.json").path
      stub_request(:delete, "https://app.datadoghq.com/api/v1/#{resource.prefix}/#{resource.id}?api_key=api_key_123&application_key=app_key_345").
        to_return(status: 200, body: JSON.dump("deleted_#{resource.class.name.split('::').last.downcase}_id" => resource.id))
      File.expects(:delete).with(resource.path)
    end
    Doggy::CLI::Delete.new.run([screen.id.to_s, monitor.id.to_s])

  end
end
