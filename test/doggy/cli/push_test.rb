require_relative '../../test_helper'

class Doggy::CLI::PushTest < Minitest::Test
  def test_sync_changes_save
    resource = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    Doggy::Model.expects(:changed_resources).returns([resource])
    stub_request(:put, "https://app.datadoghq.com/api/v1/dash/#{resource.id}?api_key=api_key_123&application_key=app_key_345").
      with(body: JSON.dump(resource.to_h.merge(read_only: true, title: resource.title + " \xF0\x9F\x90\xB6"))).
      to_return(status: 200)
    Doggy::CLI::Push.new.sync_changes
  end

  def test_sync_changes_create
    resource = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    resource.id = nil
    Doggy::Model.expects(:changed_resources).returns([resource])
    stub_request(:post, "https://app.datadoghq.com/api/v1/dash?api_key=api_key_123&application_key=app_key_345").
      with(body: JSON.dump(resource.to_h.merge(read_only: true, title: resource.title + " \xF0\x9F\x90\xB6"))).
      to_return(status: 200, body: JSON.dump(id: 1))
    File.expects(:open).with(Doggy.object_root.join('dash-1.json'), 'w')
    Doggy::CLI::Push.new.sync_changes
  end

  def test_sync_changes_destroy
    resource = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    resource.is_deleted = true
    Doggy::Model.expects(:changed_resources).returns([resource])
    stub_request(:delete, "https://app.datadoghq.com/api/v1/#{resource.prefix}/#{resource.id}?api_key=api_key_123&application_key=app_key_345").
      to_return(status: 200, body: JSON.dump(deleted_monitor_id: resource.id))
    Doggy::CLI::Push.new.sync_changes
  end

  def test_push_by_ids
    resources = prepare_for_push
    Doggy::CLI::Push.new.push_all(resources.map { |r| r.id.to_s })
  end

  def test_push_all
    prepare_for_push
    Doggy.ui.expects(:yes?).with(Doggy::CLI::Push::WARNING_MESSAGE).returns(true)
    Doggy::CLI::Push.new.push_all([])
  end

  def test_push_all_cancelled
    Doggy.ui.expects(:yes?).with(Doggy::CLI::Push::WARNING_MESSAGE).returns(false)
    Doggy.ui.expects(:say).with('Operation cancelled')
    Doggy::CLI::Push.new.push_all([])
  end

  private

  def prepare_for_push
    resources = [ Doggy::Models::Screen.new(load_fixture('screen.json')), Doggy::Models::Monitor.new(load_fixture('monitor.json')) ]
    resources.each do |resource|
      resource.expects(:ensure_read_only!)
      resource.expects(:save)
    end
    Doggy::Model.expects(:all_local_resources).returns(resources)
    resources
  end
end
