require "thor"

module Doggy
  class CLI < Thor
    include Thor::Actions

    desc "pull", "Pulls objects from Datadog"
    long_desc <<-D
      Pull objects from Datadog. All objects are pulled unless the type switches
      are used.
    D

    method_option "dashboards", type: :boolean, desc: 'Pull dashboards'
    method_option "monitors",   type: :boolean, desc: 'Pull monitors'
    method_option "screens",    type: :boolean, desc: 'Pull screens'

    def pull
      CLI::Pull.new(options.dup).run
    end

    desc "push", "Pushes objects to Datadog"
    long_desc <<-D
      Pushes objects to Datadog. Any objects that aren't skipped and don't have
      the marker in their title will get it as a result of a push.
    D

    method_option "dashboards", type: :boolean, desc: 'Pull dashboards'
    method_option "monitors",   type: :boolean, desc: 'Pull monitors'
    method_option "screens",    type: :boolean, desc: 'Pull screens'

    def push
      CLI::Push.new(options.dup).run
    end


    desc "mute OBJECT_ID OBJECT_ID OBJECT_ID", "Mutes monitor on DataDog"
    long_desc <<-D
      Mutes monitors on Datadog.
    D

    def mute(*ids)
      CLI::Mute.new(options.dup, ids).run
    end

    desc "unmute OBJECT_ID OBJECT_ID OBJECT_ID", "Unmutes monitor on DataDog"
    long_desc <<-D
      Unmutes monitors on datadog
    D

    def unmute(*ids)
      CLI::Unmute.new(options.dup, ids).run
    end

    desc "edit OBJECT_ID", "Edits an object"
    long_desc <<-D
      Edits an object
    D

    def edit(id)
      CLI::Edit.new(options.dup, id).run
    end
  end
end

