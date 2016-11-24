require_relative '../../test_helper'

class Doggy::CLI::PushTest < Minitest::Test
  def test_run_ensures_editable
    resource = Doggy::Models::Dashboard.new({'dash' => {'id' => 1, 'title' => 'Pipeline', 'read_only' => true}})
    cmd = Doggy::CLI::Edit.new({}, nil)
    resource.path = 'dummy_path'
    Dir.expects(:chdir).with(File.dirname(resource.path))
    cmd.expects(:resource_by_param).returns(resource)
    cmd.run
    refute resource.read_only
  end
end
