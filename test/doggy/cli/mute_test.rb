require_relative '../../test_helper'

class Doggy::CLI::MuteTest < Minitest::Test
  def test_run
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    Doggy::Models::Monitor.expects(:find).with(monitor.id).returns(monitor)
    monitor.expects(:toggle_mute!).with('mute', '{}')
    Doggy::CLI::Mute.new({}, [monitor.id]).run
  end
 
  def test_run_mute_with_duration
    now = Time.new(2020, 1, 1, 1, 1, 1, '+00:00')
    Time.expects(:now).returns(now)
    monitor = Doggy::Models::Monitor.new(load_fixture('monitor.json'))
    Doggy::Models::Monitor.expects(:find).with(monitor.id).returns(monitor)
    monitor.expects(:toggle_mute!).with('mute', JSON.dump({ end: 1577854861 }))
    Doggy::CLI::Mute.new({ 'duration' => '4h' }, [monitor.id]).run
  end
end
