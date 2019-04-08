# encoding: utf-8
# frozen_string_literal: true

require 'doggy/duration'

module Doggy
  class CLI::Mute
    def initialize(options, ids)
      @options = options
      @ids     = ids
    end

    def run
      monitors = @ids.map { |id| Doggy::Models::Monitor.find(id) }
      body = {}
      if @options['duration']
        body[:end] = Time.now.utc.to_i + Duration.parse(@options['duration']).to_i
      end
      body[:scope] = @options['scope'] if @options['scope']
      monitors.each { |monitor| monitor.toggle_mute!('mute', JSON.dump(body)) }
    end
  end
end
