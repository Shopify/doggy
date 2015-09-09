module Doggy
  class CLI::Pull
    attr_reader :options, :ids

    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      begin
        if ids.any?
          Doggy::Dash.download(ids)
          Doggy::Monitor.download(ids)
          Doggy::Screen.download(ids)
        else
          Doggy::Dash.download_all
          Doggy::Monitor.download_all
          Doggy::Screen.download_all
        end
      rescue DoggyError
        puts "Pull failed."
        exit 1
      end
    end
  end
end
