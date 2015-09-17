module Doggy
  class CLI::Pull
    attr_reader :options, :ids

    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      begin
        Doggy::Dash.download(ids)
        Doggy::Monitor.download(ids)
        Doggy::Screen.download(ids)
      rescue DoggyError
        puts "Pull failed."
        exit 1
      end
    end
  end
end
