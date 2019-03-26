$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'json'

require 'doggy'

require 'minitest/pride'
require 'minitest/autorun'
require 'minitest/unit'
require 'mocha/minitest'
require 'webmock/minitest'

class MiniTest::Test
  def before_setup
    Doggy.stubs(:secrets).returns({'datadog_api_key' => 'api_key_123', 'datadog_app_key' => 'app_key_345'})
    Doggy.ui.stubs(:say)
    super
  end

  def load_fixture(fixture_path)
    path = File.expand_path("fixtures/#{ fixture_path }", "#{ __FILE__ }/../")
    raw  = File.read(path)

    JSON.parse(raw)
  end
end
