module Doggy
  class CLI::Version
    def run
      begin
        print Doggy.current_version
      rescue DoggyError
        puts "Could not fetch latest SHA from DataDog."
        exit 1
      end
    end
  end
end
