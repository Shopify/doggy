require 'active_support/core_ext/module'
require 'active_support/core_ext/integer'

class Duration
  DURATION_FORMAT = /
    \A
    (?<days>\d+d)?
    (?<hours>\d+h)?
    (?<minutes>\d+m)?
    (?<seconds>\d+s)?
    \z
  /x
  DURATION_UNITS = {
    's' => :seconds,
    'm' => :minutes,
    'h' => :hours,
    'd' => :days,
  }

  def self.parse(value)
    unless match = DURATION_FORMAT.match(value)
      raise ArgumentError, "not a duration: #{value.inspect}, "\
      "use digits followed by a unit (#{DURATION_UNITS.keys.join(', ')} for #{DURATION_UNITS.values.join(', ')})"
    end
    duration = DURATION_UNITS.values.inject(0) do |as_duration, unit|
      as_duration + match[unit].to_i.public_send(unit)
    end
    new(duration)
  end

  def initialize(duration)
    @as_duration = if duration.is_a?(ActiveSupport::Duration)
                     duration
                   else
                     duration.to_i.seconds
                   end
  end

  delegate :to_i, to: :@as_duration
end
