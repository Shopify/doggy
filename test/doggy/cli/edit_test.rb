require_relative '../../test_helper'

class Doggy::CLI::EditTest < Minitest::Test
  def test_run
    dashboard = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))

    Doggy::Models::Dashboard.expects(:all_local).twice.returns([dashboard])
    Doggy::Models::Monitor.expects(:all_local).twice.returns([monitor])
    Doggy::Models::Screen.expects(:all_local).twice.returns([])

    [dashboard, monitor].each do |resource|
      resource.ensure_read_only!
      resource.path = Tempfile.new("#{resource.prefix}-#{resource.id}.json").path

      cmd = Doggy::CLI::Edit.new({}, resource.id.to_s)

      forked_resource_id = 2
      cmd.expects(:random_word).returns('randomword')
      forked_resource_attributes = resource.to_h.dup.merge(id: nil)
      if resource.is_a?(Doggy::Models::Dashboard)
        forked_resource_attributes.merge!(title: "[randomword] #{resource.title} \xF0\x9F\x90\xB6",
                                          description: '[fork of 2473] [randomword] My Dashboard', read_only: false)
      elsif resource.is_a?(Doggy::Models::Monitor)
        forked_resource_attributes.merge!(name: "[randomword] Cache expiry \xF0\x9F\x90\xB6",
                                          options: forked_resource_attributes[:options].merge(locked: false))
      end

      forked_resource_attributes = Doggy::Model.sort_by_key(forked_resource_attributes)
      stub_request(:post, "https://app.datadoghq.com/api/v1/#{resource.prefix}?api_key=api_key_123&application_key=app_key_345").
        with(body: JSON.dump(forked_resource_attributes)).
             to_return(status: 200, body: "{\"id\":#{forked_resource_id}}")
      if resource.is_a?(Doggy::Models::Dashboard)
        JSON.expects(:pretty_generate).with(forked_resource_attributes.merge(id: forked_resource_id, read_only: true))
      elsif resource.is_a?(Doggy::Models::Monitor)
        JSON.expects(:pretty_generate).with(forked_resource_attributes.merge(id: forked_resource_id, options: forked_resource_attributes[:options].merge(locked: true)))
      end
      cmd.expects(:system).with("open '#{resource.class.new(id: forked_resource_id).human_edit_url}'")
      cmd.expects(:wait_for_edit)

      new_resource_attributes = resource.to_h.dup
      if resource.is_a?(Doggy::Models::Dashboard)
        graph = new_resource_attributes[:graphs][0].dup
        new_resource_attributes[:graphs] = [graph.merge('title' => 'Not Average Memory Free anymore')]
      end
      stub_request(:get, "https://app.datadoghq.com/api/v1/#{resource.prefix}/2?api_key=api_key_123&application_key=app_key_345").
        to_return(status: 200, body: JSON.dump(new_resource_attributes.merge(id: forked_resource_id)))
      JSON.expects(:pretty_generate).with(new_resource_attributes)

      stub_request(:delete, "https://app.datadoghq.com/api/v1/#{resource.prefix}/2?api_key=api_key_123&application_key=app_key_345").
        to_return(status: 200)

      cmd.run
    end
  end
end
