module Doggy
  class CLI::Unmute
    def initialize(options, ids)
      @options = options
      @ids     = ids
    end

    def run
      monitors = @ids.map { |id| Doggy::Models::Monitor.find(id) }
      monitors.each(&:unmute)
    end
  end
end


