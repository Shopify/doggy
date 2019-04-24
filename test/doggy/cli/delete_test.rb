# frozen_string_literal: true

require_relative '../../test_helper'

class Doggy::CLI::DeleteTest < Minitest::Test
  def setup
    Doggy.stubs(:secrets).returns('datadog_api_key' => 'api_key_123', 'datadog_app_key' => 'app_key_345')
    Doggy.ui.stubs(:say)
  end

  def test_run
    dashboard = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    dashboard.path = Tempfile.new("#{dashboard.prefix}-#{dashboard.id}.json").path
    stub_request(:delete, "https://app.datadoghq.com/api/v1/#{dashboard.prefix}/#{dashboard.id}?api_key=api_key_123&application_key=app_key_345")
      .to_return(status: 200, body: JSON.dump("deleted_#{dashboard.class.name.split('::').last.downcase}_id" => dashboard.id))
    File.expects(:delete).with(dashboard.path)

    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    stub_request(:delete, "https://app.datadoghq.com/api/v1/#{monitor.prefix}/#{monitor.id}?api_key=api_key_123&application_key=app_key_345")
      .to_return(status: 200, body: JSON.dump(errors: 'Could not find the monitor'))
    Doggy.ui.expects(:error)

    Doggy::Model.expects(:all_local_resources).returns([dashboard, monitor])

    Doggy::CLI::Delete.new.run([dashboard.id.to_s, monitor.id.to_s])
  end

  def test_run_when_remote_destroy_fails
    dashboard = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    Doggy::Model.expects(:all_local_resources).returns([dashboard, monitor])
    [dashboard, monitor].each do |resource|
      resource.path = Tempfile.new("#{resource.prefix}-#{resource.id}.json").path
      stub_request(:delete, "https://app.datadoghq.com/api/v1/#{resource.prefix}/#{resource.id}?api_key=api_key_123&application_key=app_key_345")
        .to_return(status: 404, body: JSON.dump("deleted_#{resource.class.name.split('::').last.downcase}_id" => resource.id))
      File.expects(:delete).with(resource.path)
    end
    Doggy::CLI::Delete.new.run([dashboard.id.to_s, monitor.id.to_s])
  end
end
