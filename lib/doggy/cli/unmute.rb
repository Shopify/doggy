module Doggy
  class CLI::Unmute
    attr_reader :options, :ids

    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      begin
        Doggy::Monitor.unmute(ids)
      rescue DoggyError
        puts "Unmute failed."
        exit 1
      end
    end
  end
end
