# encoding: utf-8

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

    def pull(*ids)
      CLI::Pull.new(options.dup, ids).run
    end

    desc "sync", "Pushes the changes to Datadog"
    long_desc <<-D
      Performs git diff between the HEAD and last deployed SHA to get the changes,
      then accordingly either deletes or pushes an object to Datadog.
    D

    def sync(*ids)
      CLI::Push.new.sync_changes
    end

    desc "push", "Hard pushes objects to Datadog"
    long_desc <<-D
      Pushes objects to Datadog. You can provide list of IDs to scope it to certain objects,
      otherwise it will push all local objects to Datadog. The changes in Datadog that are not in
      the repository will be overridden. This action does not delete anything.
    D

    def push(*ids)
      CLI::Push.new.push_all(ids)
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

