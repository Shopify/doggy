module Doggy
  class CLI::Create
    attr_reader :options, :kind, :name

    def initialize(options, kind, name)
      @options = options
      @kind = kind
      @name = name
    end

    def run
      begin
        case kind
        when 'dash', 'dashboard'     then Doggy::Dash.create(name)
        when 'alert', 'monitor'      then Doggy::Monitor.create(name)
        when 'screen', 'screenboard' then Doggy::Screen.create(name)
        else puts 'Unknown item type'
        end
      rescue DoggyError
        puts "Create failed."
        exit 1
      end
    end
  end
end
