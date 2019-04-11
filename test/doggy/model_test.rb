# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'

class Doggy::ModelTest < Minitest::Test
  class DummyModel < Doggy::Model
    attribute :id,    Integer
    attribute :title, String
  end

  class DummyModelWithRoot < DummyModel
    self.root = 'dash'
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

      screen_json = load_fixture('screen.json')
      screen = Doggy::Models::Screen.new(screen_json)
      git_create(repo, "objects/screen-#{screen.id}.json", JSON.dump(screen_json))

      dashboard_to_delete = Doggy::Models::Dashboard.new(id: '666')
      git_create(repo, "objects/dash-#{dashboard_to_delete.id}.json", JSON.dump(dashboard_to_delete.to_h))

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
      git_create(repo, "objects/dash-#{dashboard.id}.json", JSON.dump(dashboard_json['dash']))

      # modify the existing monitor
      monitor.name = 'An updated monitor name'
      git_create(repo, "objects/monitor-#{monitor.id}.json", JSON.dump(monitor.to_h))

      # rename the screen
      oid = repo.write(JSON.dump(screen_json), :blob)
      repo.index.remove("objects/screen-#{screen.id}.json")
      repo.index.add(path: "objects/new-folder/screen-#{screen.id}.json", oid: oid, mode: 0100644)
      git_commit(repo)

      # delete the dashboard
      repo.index.remove("objects/dash-#{dashboard_to_delete.id}.json")
      git_commit(repo)

      # build expected objects and assert that the method returns them
      [dashboard, monitor, screen, dashboard_to_delete].each do |resource|
        resource.is_deleted = false
        resource.path = Doggy.object_root.parent.join("objects/#{resource.prefix}-#{resource.id}.json").to_s
        resource.loading_source = :local
      end
      screen.path = Doggy.object_root.parent.join("objects/new-folder/screen-#{screen.id}").to_s
      dashboard_to_delete.is_deleted = true

      assert_equal([dashboard, monitor, screen, dashboard_to_delete].sort_by(&:id),\
        Doggy::Model.changed_resources.sort_by(&:id))
    ensure
      FileUtils.remove_entry(repo_root)
    end
  end

  def test_find_local
    dashboard = Doggy::Models::Dashboard.new(load_fixture('dashboard.json'))
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    monitor.path = File.join(Doggy.object_root, 'some-folder/monitor-22.json')
    screen = Doggy::Models::Screen.new(load_fixture('screen.json'))
    Doggy::Model.expects(:all_local_resources).times(6).returns([dashboard, monitor, screen])
    assert_equal(dashboard, Doggy::Model.find_local(2473))
    assert_equal(dashboard, Doggy::Model.find_local('2473'))
    assert_equal(dashboard, Doggy::Model.find_local('https://app.datadoghq.com/dash/2473'))
    assert_equal(monitor, Doggy::Model.find_local('https://app.datadoghq.com/monitors#22/edit'))
    assert_equal(monitor, Doggy::Model.find_local('objects/some-folder/monitor-22.json'))
    assert_equal(screen, Doggy::Model.find_local('https://app.datadoghq.com/screen/10/bbbb'))
  end

  def test_save_local_ensures_read_only
    monitor = Doggy::Models::Monitor.new(id: 1, title: 'Some test', name: 'Monitor name', options: { locked: false })
    monitor.path = Tempfile.new('monitor-1.json').path
    monitor.save_local
    assert(monitor.options.locked)

    dashboard = Doggy::Models::Dashboard.new('dash' => { 'title' => 'Pipeline', 'read_only' => false })
    dashboard.path = Tempfile.new('dash-1.json').path
    dashboard.save_local
    assert(dashboard.read_only)
  end

  def test_create
    model = Doggy::Models::Dashboard.new('dash' => { 'title' => 'Pipeline', 'read_only' => true })
    stub_request(:post, 'https://app.datadoghq.com/api/v1/dash?api_key=api_key_123&application_key=app_key_345')
      .with(body: "{\"description\":null,\"graphs\":[],\"id\":null,\"read_only\":true,\"template_variables\":[],\"title\":\"Pipeline 🐶\"}")
      .to_return(status: 201, body: "{\"id\":1}")
    File.expects(:open).with(Doggy.object_root.join('dash-1.json'), 'w')
    model.save
  end

  def test_create_when_api_error
    model = Doggy::Models::Dashboard.new('dash' => { 'title' => 'Pipeline', 'read_only' => true })
    stub_request(:post, 'https://app.datadoghq.com/api/v1/dash?api_key=api_key_123&application_key=app_key_345')
      .with(body: "{\"description\":null,\"graphs\":[],\"id\":null,\"read_only\":true,\"template_variables\":[],\"title\":\"Pipeline 🐶\"}")
      .to_return(status: 400, body: "{}")
    File.expects(:open).with(Doggy.object_root.join('dash-1.json'), 'w').times(0)
    assert_raises Doggy::DoggyError do
      model.save
    end
  end

  def test_update
    model = Doggy::Models::Monitor.new(id: 1, title: 'Some test', name: 'Monitor name')
    stub_request(:put, "https://app.datadoghq.com/api/v1/monitor/1?api_key=api_key_123&application_key=app_key_345")
      .with(body: "{\"id\":1,\"message\":null,\"multi\":null,\"name\":\"Monitor name 🐶\",\"options\":{},"\
           "\"org_id\":null,\"query\":null,\"tags\":[],\"type\":null}")
      .to_return(status: 200)
    model.save
  end

  def test_find_missing
    stub_test_find(400)
    assert_raises Doggy::DoggyError do
      Doggy::Models::Monitor.find(1)
    end
  end

  def test_find_success
    stub_test_find(404)
    Doggy::Models::Monitor.find(1)
  end

  def test_sort_by_key
    h = { b: [{ d: 1, a: 2 }, { x: 1, p: 3, y: 5 }], a: 3 }
    expected = { a: 3, b: [{ a: 2, d: 1 }, { p: 3, x: 1, y: 5 }] }
    assert_equal(Doggy::Model.sort_by_key(h).to_s, expected.to_s)
  end

  def test_mass_assignment
    instance = DummyModel.new(id: 1, title: 'Some test')

    assert_equal(1,           instance.id)
    assert_equal('Some test', instance.title)
  end

  def test_value_coallescion
    instance = DummyModel.new(id: '2', title: :a_symbol)

    assert_equal(2,          instance.id)
    assert_equal('a_symbol', instance.title)
  end

  def test_root
    first_instance  = DummyModelWithRoot.new('dash' => { 'id' => 1, 'title' => 'Pipeline' })
    second_instance = DummyModelWithRoot.new(id: 2, title: 'RPMs')

    assert_equal(1,          first_instance.id)
    assert_equal('Pipeline', first_instance.title)

    assert_equal(2,      second_instance.id)
    assert_equal('RPMs', second_instance.title)
  end

  def test_type_inferrence
    assert_equal(Doggy::Models::Dashboard, Doggy::Model.infer_type('graphs'      => []))
    assert_equal(Doggy::Models::Monitor,   Doggy::Model.infer_type('message'     => ''))
    assert_equal(Doggy::Models::Screen,    Doggy::Model.infer_type('board_title' => ''))
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
