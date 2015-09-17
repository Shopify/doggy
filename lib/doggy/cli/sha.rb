module Doggy
  class CLI::Sha
    def run
      begin
        print Doggy.current_sha
      rescue DoggyError
        puts "Could not fetch latest SHA from DataDog."
        exit 1
      end
    end
  end
end
