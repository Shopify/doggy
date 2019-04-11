# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'json'

require 'doggy'

require 'minitest/autorun'
require 'minitest/unit'
require 'mocha/minitest'
require 'webmock/minitest'

class MiniTest::Test
  def load_fixture(fixture_path)
    path = File.expand_path("fixtures/#{fixture_path}", "#{__FILE__}/../")
    raw  = File.read(path)

    JSON.parse(raw)
  end
end
