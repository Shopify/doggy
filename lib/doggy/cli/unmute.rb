# frozen_string_literal: true

module Doggy
  class CLI::Unmute
    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      monitors = @ids.map { |id| Doggy::Models::Monitor.find(id) }
      body = {}
      body[:all_scopes] = true if @options['all_scopes']
      body[:scope] = @options['scope'] if @options['scope']
      monitors.each { |monitor| monitor.toggle_mute!('unmute', JSON.dump(body)) }
    end
  end
end
