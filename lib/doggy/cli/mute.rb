module Doggy
  class CLI::Mute
    attr_reader :options, :ids

    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      begin
        Doggy::Monitor.mute(ids)
      rescue DoggyError
        puts "Mute failed."
        exit 1
      end
    end
  end
end
