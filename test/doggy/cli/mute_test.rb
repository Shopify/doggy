require_relative '../../test_helper'

class Doggy::CLI::MuteTest < Minitest::Test
  def test_run
    mocked_run
    now = Time.new(2020, 1, 1, 1, 1, 1, '+00:00')
    Time.expects(:now).twice.returns(now)
    mocked_run({ 'duration' => '4h' }, { end: 1577854861 })
    mocked_run({ 'duration' => '4h', 'scope' => 'role:db' }, { end: 1577854861, scope: 'role:db' })
  end

  private

  def mocked_run(options = {}, body = {})
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    Doggy::Models::Monitor.expects(:find).with(monitor.id).returns(monitor)
    monitor.expects(:toggle_mute!).with('mute', JSON.dump(body))
    Doggy::CLI::Mute.new(options, [monitor.id]).run
  end
end
