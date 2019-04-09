# frozen_string_literal: true

# Copied from https://github.com/Shopify/spy/blob/ac7bfb9550bfd7bafd191bc31f1bcd9dc4ce9ee6/lib/spy/duration.rb
# and edited accordingly

require 'active_support/core_ext/module'
require 'active_support/core_ext/integer'

module Duration
  DURATION_FORMAT = %r{
    \A
    (?<days>\d+d)?
    (?<hours>\d+h)?
    (?<minutes>\d+m)?
    (?<seconds>\d+s)?
    \z
  }x
  DURATION_UNITS = {
    's' => :seconds,
    'm' => :minutes,
    'h' => :hours,
    'd' => :days,
  }

  def self.parse(value)
    unless match = DURATION_FORMAT.match(value)
      raise ArgumentError, "not a duration: #{value.inspect}, "\
      "use digits followed by a unit (#{DURATION_UNITS.map { |k, v| "#{k} for #{v}" }.join(', ')})"
    end
    DURATION_UNITS.values.inject(0) do |sum, unit|
      sum + match[unit].to_i.public_send(unit)
    end.seconds
  end
end
