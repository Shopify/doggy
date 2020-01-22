# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'

class Doggy::ModelTest < Minitest::Test
  class DummyModel < Doggy::Model
  end

  def setup
    Doggy.stubs(:secrets).returns('datadog_api_key' => 'api_key_123', 'datadog_app_key' => 'app_key_345')
    Doggy.ui.stubs(:say)
  end

  def test_changed_resources
    repo_root = Dir.mktmpdir
    Doggy.expects(:object_root).at_least_once.returns(Pathname.new('objects').expand_path(repo_root))
    begin
      repo = Rugged::Repository.init_at(repo_root)

      git_create(repo, 'Gemfile', "source 'https://rubygems.org'\n\ngemspec")

      dashboard_to_delete = Doggy::Models::Dashboard.new(id: '666')
      git_create(repo, "objects/dashboard-#{dashboard_to_delete.id}.json", JSON.dump(dashboard_to_delete.to_h))

      monitor_json = load_fixture('monitor.json')
      monitor = Doggy::Models::Monitor.new(monitor_json)
      last_deployed_commit_sha = git_create(repo, "objects/monitor-#{monitor.id}.json", JSON.dump(monitor_json))
      Doggy::Model.expects(:current_sha).returns(last_deployed_commit_sha)

      # so the above commits are deployed, now we do some changes on the repo

      # modify the non Datadog file - this is to test that changed_resources ignores non datadog diffs
      git_create(repo, 'Gemfile', 'source "https://rubygems.org"')

      # create a new dashboard
      dashboard_json = load_fixture('dashboard.json')
      dashboard = Doggy::Models::Dashboard.new(dashboard_json)
      git_create(repo, "objects/dashboard-#{dashboard.id}.json", JSON.dump(dashboard_json))

      # modify the existing monitor
      monitor.name = 'An updated monitor name'
      git_create(repo, "objects/monitor-#{monitor.id}.json", JSON.dump(monitor.to_h))

      # rename the dashboard
      # oid = repo.write(JSON.dump(dashboard_json), :blob)
      # repo.index.remove("objects/dashboard-#{dashboard.id}.json")
      # repo.index.add(path: "objects/new-folder/dashboard-#{dashboard.id}.json", oid: oid, mode: 0100644)
      # git_commit(repo)

      # delete the dashboard
      repo.index.remove("objects/dashboard-#{dashboard_to_delete.id}.json")
      git_commit(repo)

      # build expected objects and assert that the method returns them
      [dashboard, monitor, dashboard_to_delete].each do |resource|
        resource.is_deleted = false
        resource.path = Doggy.object_root.parent.join("objects/#{resource.prefix}-#{resource.id}.json").to_s
        resource.loading_source = :local
      end
      dashboard_to_delete.is_deleted = true

      assert_equal([dashboard, dashboard_to_delete, monitor], Doggy::Model.changed_resources)
    ensure
      FileUtils.remove_entry(repo_root)
    end
  end

  def test_changed_resources_rename_and_modify_same_commit
    repo_root = Dir.mktmpdir
    Doggy.expects(:object_root).at_least_once.returns(Pathname.new('objects').expand_path(repo_root))
    begin
      repo = Rugged::Repository.init_at(repo_root)

      # create a new dashboard
      dashboard_json = load_fixture('dashboard.json')
      dashboard = Doggy::Models::Dashboard.new(dashboard_json)
      last_deployed_commit_sha = git_create(repo, "objects/dashboard-#{dashboard.id}.json", JSON.dump(dashboard_json))
      Doggy::Model.expects(:current_sha).returns(last_deployed_commit_sha)

      # rename the dashboard and alter it
      dashboard_json["description"] = "A more informative description"
      oid = repo.write(JSON.dump(dashboard_json), :blob)
      repo.index.remove("objects/dashboard-#{dashboard.id}.json")
      repo.index.add(path: "objects/new-folder/dashboard-#{dashboard.id}.json", oid: oid, mode: 0100644)
      git_commit(repo)

      # build expected objects and assert that the method returns them
      [dashboard].each do |resource|
        resource.is_deleted = false
        resource.path = Doggy.object_root.parent.join("objects/#{resource.prefix}-#{resource.id}.json").to_s
        resource.loading_source = :local
      end

      assert_equal([dashboard], Doggy::Model.changed_resources)
    ensure
      FileUtils.remove_entry(repo_root)
    end
  end

  def test_find_local
    dashboard = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    monitor.path = File.join(Doggy.object_root, 'some-folder/monitor-22.json')

    Doggy::Model.expects(:all_local_resources).at_least_once.returns([dashboard, monitor])

    assert_equal(dashboard, Doggy::Model.find_local(2473))
    assert_equal(dashboard, Doggy::Model.find_local('2473'))
    assert_equal(monitor, Doggy::Model.find_local('objects/some-folder/monitor-22.json'))
    assert_equal(dashboard, Doggy::Model.find_local('https://app.datadoghq.com/dashboard/2473'))
    assert_equal(monitor, Doggy::Model.find_local('https://app.datadoghq.com/monitors#22/edit'))
  end

  def test_save_local_ensures_read_only
    monitor = Doggy::Models::Monitor.new(id: 1, title: 'Some test', name: 'Monitor name', options: { locked: false })
    monitor.path = Tempfile.new('monitor-1.json').path
    monitor.save_local
    assert(monitor.attributes["options"]["locked"])

    dashboard = Doggy::Models::Dashboard.new('title' => 'Pipeline', 'read_only' => false)
    dashboard.path = Tempfile.new('dashboard-1.json').path
    dashboard.save_local
    assert(dashboard.read_only)
  end

  def test_create
    model = Doggy::Models::Dashboard.new('title' => 'Pipeline', 'read_only' => true, 'widgets' => [])

    stub_request(:post, 'https://app.datadoghq.com/api/v1/dashboard?api_key=api_key_123&application_key=app_key_345')
      .with(body: "{\"title\":\"Pipeline 🐶\",\"read_only\":true,\"widgets\":[]}")
      .to_return(status: 201, body: "{\"id\":1}")

    File.expects(:open).with(Doggy.object_root.join('dashboard-1.json'), 'w')

    model.save
  end

  def test_create_when_api_error
    model = Doggy::Models::Dashboard.new('title' => 'Pipeline', 'read_only' => true, 'widgets' => [])

    stub_request(:post, 'https://app.datadoghq.com/api/v1/dashboard?api_key=api_key_123&application_key=app_key_345')
      .with(body: "{\"title\":\"Pipeline 🐶\",\"read_only\":true,\"widgets\":[]}")
      .to_return(status: 500, body: "{}")

    File.expects(:open).with(Doggy.object_root.join('dashboard-1.json'), 'w').times(0)

    assert_raises Doggy::DoggyError do
      model.save
    end
  end

  def test_update
    model = Doggy::Models::Monitor.new(id: 1, title: 'Some test', name: 'Monitor name')
    stub_request(:put, "https://app.datadoghq.com/api/v1/monitor/1?api_key=api_key_123&application_key=app_key_345")
      .with(body: "{\"id\":\"1\",\"title\":\"Some test\",\"name\":\"Monitor name 🐶\",\"options\":{}}")
      .to_return(status: 200)
    model.save
  end

  def test_find_missing
    stub_test_find(499)
    assert_raises Doggy::DoggyError do
      Doggy::Models::Monitor.find(1)
    end
  end

  def test_find_success
    stub_test_find(404)
    Doggy::Models::Monitor.find(1)
  end

  def test_mass_assignment
    instance = DummyModel.new(id: "1", title: 'Some test')

    assert_equal("1",         instance.attributes["id"])
    assert_equal('Some test', instance.attributes["title"])
  end

  def test_value_coallescion
    instance = DummyModel.new(id: '2', title: "a_symbol")

    assert_equal("2",        instance.attributes["id"])
    assert_equal('a_symbol', instance.attributes["title"])
  end

  def test_type_inferrence
    assert_equal(Doggy::Models::Dashboard, Doggy::Model.infer_type('widgets' => []))
    assert_equal(Doggy::Models::Monitor,   Doggy::Model.infer_type('message' => ''))
  end

  private

  def stub_test_find(return_code)
    Doggy::Models::Monitor.new(id: 1, title: 'Some test', name: 'Monitor name')
    stub_request(:get, "https://app.datadoghq.com/api/v1/monitor/1?api_key=api_key_123&application_key=app_key_345")
      .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby' })
      .to_return(status: return_code, body: "{\"errors\":[]}", headers: {})
  end

  def git_create(repo, path, content)
    oid = repo.write(content, :blob)
    repo.index.read_tree(repo.head.target.tree) unless repo.empty?
    repo.index.add(path: path, oid: oid, mode: 0100644)
    git_commit(repo)
  end

  def git_commit(repo)
    options = {}
    options[:tree] = repo.index.write_tree(repo)
    options[:author] = { email: 'testuser@github.com', name: 'Test Author', time: Time.now }
    options[:committer] = { email: 'testuser@github.com', name: 'Test Author', time: Time.now }
    options[:message] = "Making a commit via Rugged! #{Doggy.random_word}"
    options[:parents] = repo.empty? ? [] : [repo.head.target].compact
    options[:update_ref] = 'HEAD'
    Rugged::Commit.create(repo, options)
  end
end
