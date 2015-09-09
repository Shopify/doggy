module Doggy
  class CLI::Push
    attr_reader :options, :ids

    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      begin
        if ids.any?
          Doggy::Dash.upload(ids)
          Doggy::Monitor.upload(ids)
          Doggy::Screen.upload(ids)
        else
          Doggy::Dash.upload_all
          Doggy::Monitor.upload_all
          Doggy::Screen.upload_all
          Doggy.emit_shipit_deployment if ENV['SHIPIT']
        end
      rescue DoggyError
        puts "Push failed."
        exit 1
      end
    end
  end
end
