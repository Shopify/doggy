# encoding: utf-8

module Doggy
  class CLI::Mute
    def initialize(options, ids)
      @options = options
      @ids     = ids
    end

    def run
      monitors = @ids.map { |id| Doggy::Models::Monitor.find(id) }
      monitors.each { |monitor| monitor.toggle_mute!('mute') }
    end
  end
end

