require_relative '../../test_helper'

class Doggy::CLI::PushTest < Minitest::Test
  def test_push_ensures_read_only
    model = Doggy::Models::Dashboard.new({'dash' => {'id' => 1, 'title' => 'Pipeline'}})
    Doggy::Models::Dashboard.expects(:all_local).returns([model])
    Doggy::Models::Monitor.expects(:all_local).returns([])
    Doggy::Models::Screen.expects(:all_local).returns([])
    stub_request(:put, "https://app.datadoghq.com/api/v1/dash/1?api_key=api_key_123&application_key=app_key_345").
      with(:body => "{\"description\":null,\"graphs\":[],\"id\":1,\"read_only\":true,\"template_variables\":[],\"title\":\"Pipeline 🐶\"}").
      to_return(:status => 200, :body => "")

    Doggy::CLI::Push.new({'dashboards' => true, 'monitors' => true, 'screens' => true}).run
  end
end
