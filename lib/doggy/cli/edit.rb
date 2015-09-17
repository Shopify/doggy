module Doggy
  class CLI::Edit
    attr_reader :options, :id

    def initialize(options, id)
      @options = options
      @id = id
    end

    def run
      Doggy.edit(id)
    end
  end
end
