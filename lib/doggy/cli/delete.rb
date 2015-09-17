module Doggy
  class CLI::Delete
    attr_reader :options, :ids

    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      begin
        Doggy::Dash.delete(ids)
        Doggy::Monitor.delete(ids)
        Doggy::Screen.delete(ids)
      rescue DoggyError
        puts "Delete failed."
        exit 1
      end
    end
  end
end
