require 'thor'
require 'doggy'

module Doggy
  class CLI < Thor
    include Thor::Actions

    def self.start(*)
      super
    rescue Exception => e
      raise e
    ensure
    end

    def initialize(*args)
      super
    rescue UnknownArgumentError => e
      raise Doggy::InvalidOption, e.message
    ensure
      self.options ||= {}
    end

    check_unknown_options!(:except => [:config, :exec])
    stop_on_unknown_option! :exec

    desc "pull [SPACE SEPARATED IDs]", "Pulls objects from DataDog"
    long_desc <<-D
      Pull objects from DataDog. If pull is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def pull(*ids)
      require 'doggy/cli/pull'
      Pull.new(options.dup, ids).run
    end

    desc "push [SPACE SEPARATED IDs]", "Pushes objects to DataDog"
    long_desc <<-D
      Pushes objects to DataDog. If push is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def push(*ids)
      require 'doggy/cli/push'
      Push.new(options.dup, ids).run
    end

    desc "create OBJECT_TYPE OBJECT_NAME", "Creates a new object on DataDog"
    long_desc <<-D
      Creates a new object on DataDog. If create is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def create(kind, name)
      require 'doggy/cli/create'
      Create.new(options.dup, kind, name).run
    end

    desc "delete SPACE SEPARATED IDs", "Deletes objects from DataDog"
    long_desc <<-D
      Deletes objects from DataDog. If delete is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def delete(*ids)
      require 'doggy/cli/delete'
      Delete.new(options.dup, ids).run
    end

    desc "mute [SPACE SEPARATED IDs]", "Mutes monitor on DataDog"
    long_desc <<-D
      Mutes monitor on DataDog. If mute is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def mute(*ids)
      require 'doggy/cli/mute'
      Mute.new(options.dup, ids).run
    end

    desc "unmute [SPACE SEPARATED IDs]", "Unmutes monitor on DataDog"
    long_desc <<-D
      Deletes objects from DataDog. If delete is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def unmute(*ids)
      require 'doggy/cli/unmute'
      Unmute.new(options.dup, ids).run
    end

    desc "version", "Detects the most recent SHA deployed by ShipIt"
    long_desc <<-D
      Scans DataDog event stream for shipit events what contain most recently deployed version
      of DataDog properties.
      If not, the error is displayed and Doggy exits status 1.
    D
    def version
      require 'doggy/cli/version'
      Version.new.run
    end
  end
end
