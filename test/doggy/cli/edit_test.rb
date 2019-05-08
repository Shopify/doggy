# frozen_string_literal: true

require_relative '../../test_helper'

class Doggy::CLI::EditTest < Minitest::Test
  def setup
    Doggy.stubs(:secrets).returns('datadog_api_key' => 'api_key_123', 'datadog_app_key' => 'app_key_345')
    Doggy.ui.stubs(:say)
  end

  def test_run
    dashboard = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))

    Doggy::Model.expects(:all_local_resources).at_least_once.returns([dashboard, monitor])

    [dashboard].each do |resource|
      resource.ensure_read_only!
      resource.path = Tempfile.new("#{resource.prefix}-#{resource.id}.json").path

      cmd = Doggy::CLI::Edit.new({}, resource.id.to_s)

      forked_resource_id = "2"
      Doggy.expects(:random_word).returns('randomword')
      forked_resource_attributes = resource.to_h.dup.except("id")

      if resource.is_a?(Doggy::Models::Dashboard)
        forked_resource_attributes["title"] = "[randomword] #{resource.title} 🐶"
        forked_resource_attributes["is_read_only"] = false
      elsif resource.is_a?(Doggy::Models::Monitor)
        forked_resource_attributes["name"] = "[randomword] Cache expiry 🐶"
        forked_resource_attributes["options"]["locked"] = false
      end

      forked_resource_attributes = Doggy::Model.sort_by_key(forked_resource_attributes)
      stub_request(:post, "https://app.datadoghq.com/api/v1/#{resource.prefix}?api_key=api_key_123&application_key=app_key_345")
        .with(body: JSON.dump(forked_resource_attributes))
        .to_return(status: 200, body: "{\"id\":#{forked_resource_id}}")
      if resource.is_a?(Doggy::Models::Dashboard)
        JSON.expects(:pretty_generate).with(forked_resource_attributes.merge("id" => forked_resource_id, "is_read_only" => true))
      elsif resource.is_a?(Doggy::Models::Monitor)
        JSON.expects(:pretty_generate).with(forked_resource_attributes.merge("id" => forked_resource_id, "options" => forked_resource_attributes["options"].merge("locked" => true)))
      end

      cmd.expects(:system).with("open '#{resource.class.new('id' => forked_resource_id).human_edit_url}'")
      cmd.expects(:wait_for_edit)

      new_resource_attributes = resource.to_h.dup
      stub_request(:get, "https://app.datadoghq.com/api/v1/#{resource.prefix}/2?api_key=api_key_123&application_key=app_key_345")
        .to_return(status: 200, body: JSON.dump(new_resource_attributes.merge("id" => forked_resource_id)))
      JSON.expects(:pretty_generate).with(new_resource_attributes)

      stub_request(:delete, "https://app.datadoghq.com/api/v1/#{resource.prefix}/2?api_key=api_key_123&application_key=app_key_345")
        .to_return(status: 200)

      cmd.run
    end
  end
end
