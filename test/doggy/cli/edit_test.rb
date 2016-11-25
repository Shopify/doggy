require_relative '../../test_helper'

class Doggy::CLI::PushTest < Minitest::Test
  def test_run
    fixture = load_fixture('dashboard.json')
    resource = Doggy::Models::Dashboard.new(fixture)
    resource.read_only = true
    file = Tempfile.new("dash-#{resource.id}.json")
    resource.path = file.path

    Doggy::Models::Dashboard.expects(:all_local).returns([resource])
    Doggy::Models::Monitor.expects(:all_local).returns([])
    Doggy::Models::Screen.expects(:all_local).returns([])

    cmd = Doggy::CLI::Edit.new({}, resource.id.to_s)

    forked_resource_id = 2
    cmd.expects(:random_word).returns('randomword')
    forked_resource_attributes = {
      description: '[fork of 2473] [randomword] My Dashboard',
      graphs: resource.graphs.dup,
      id: nil,
      read_only: true, template_variables: [], title: "[randomword] #{resource.title} \xF0\x9F\x90\xB6"
    }
    stub_request(:post, "https://app.datadoghq.com/api/v1/dash?api_key=api_key_123&application_key=app_key_345").
      with(body: JSON.dump(forked_resource_attributes)).
           to_return(status: 200, body: "{\"id\":#{forked_resource_id}}")
    JSON.expects(:pretty_generate).with(forked_resource_attributes.merge(id: forked_resource_id))
    cmd.expects(:system).with("open 'https://app.datadoghq.com/dash/#{forked_resource_id}'")
    cmd.expects(:wait_for_edit)

    graph = resource.to_h[:graphs][0].dup
    new_resource_attributes = resource.to_h.dup
    new_resource_attributes[:graphs] = [graph.merge('title' => 'Not Average Memory Free anymore')]
    stub_request(:get, "https://app.datadoghq.com/api/v1/dash/2?api_key=api_key_123&application_key=app_key_345").
      to_return(status: 200, body: JSON.dump(new_resource_attributes.merge(id: forked_resource_id)))
    JSON.expects(:pretty_generate).with(new_resource_attributes)

    stub_request(:delete, "https://app.datadoghq.com/api/v1/dash/2?api_key=api_key_123&application_key=app_key_345").
      to_return(status: 200)

    cmd.run

    refute resource.read_only
  end
end
