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

    desc "pull OBJECT_ID OBJECT_ID OBJECT_ID", "Pulls objects from DataDog"
    long_desc <<-D
      Pull objects from DataDog. If pull is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def pull(*ids)
      require 'doggy/cli/pull'
      Pull.new(options.dup, ids).run
    end

    desc "push [OBJECT_ID OBJECT_ID OBJECT_ID]", "Pushes objects to DataDog"
    long_desc <<-D
      Pushes objects to DataDog. If push is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def push(*ids)
      require 'doggy/cli/push'
      Push.new(options.dup, ids).run
    end

    desc "edit OBJECT_ID", "Edit an existing object on DataDog"
    long_desc <<-D
      Opens default browser pointing to an object to edit it visually. After you finish, it will
      display edit result.
    D
    def edit(id)
      require 'doggy/cli/edit'
      Edit.new(options.dup, id).run
    end

    desc "delete OBJECT_ID OBJECT_ID OBJECT_ID", "Deletes objects from DataDog"
    long_desc <<-D
      Deletes objects from DataDog. If delete is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def delete(*ids)
      require 'doggy/cli/delete'
      Delete.new(options.dup, ids).run
    end

    desc "mute OBJECT_ID OBJECT_ID OBJECT_ID", "Mutes monitor on DataDog"
    long_desc <<-D
      Mutes monitor on DataDog. If mute is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def mute(*ids)
      require 'doggy/cli/mute'
      Mute.new(options.dup, ids).run
    end

    desc "unmute OBJECT_ID OBJECT_ID OBJECT_ID", "Unmutes monitor on DataDog"
    long_desc <<-D
      Deletes objects from DataDog. If delete is successful, Doggy exits with a status of 0.
      If not, the error is displayed and Doggy exits status 1.
    D
    def unmute(*ids)
      require 'doggy/cli/unmute'
      Unmute.new(options.dup, ids).run
    end

    desc "sha", "Detects the most recent SHA deployed by ShipIt"
    long_desc <<-D
      Scans DataDog event stream for shipit events what contain most recently deployed version
      of DataDog properties.
      If not, the error is displayed and Doggy exits status 1.
    D
    def sha
      require 'doggy/cli/sha'
      Sha.new.run
    end

    desc "version", "Prints Doggy version"
    long_desc <<-D
      Prints Doggy version
    D
    def version
      require 'doggy/cli/version'
      Version.new.run
    end
  end
end
