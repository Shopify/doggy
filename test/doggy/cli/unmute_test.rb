require_relative '../../test_helper'

class Doggy::CLI::UnmuteTest < Minitest::Test
  def test_run
    mocked_run
    mocked_run({ 'scope' => 'role:db' }, { scope: 'role:db' })
    mocked_run({ 'all_scopes' => false }, {})
    mocked_run({ 'all_scopes' => true }, { all_scopes: true })
  end

  private

  def mocked_run(options = {}, body = {})
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    Doggy::Models::Monitor.expects(:find).with(monitor.id).returns(monitor)
    monitor.expects(:toggle_mute!).with('unmute', JSON.dump(body))
    Doggy::CLI::Unmute.new(options, [monitor.id]).run
  end
end
