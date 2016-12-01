# encoding: utf-8

require "thor"

module Doggy
  class CLI < Thor
    include Thor::Actions

    desc "pull [IDs]", "Pulls objects from Datadog"

    def pull(*ids)
      CLI::Pull.new(options.dup, ids).run
    end

    desc "delete IDs", "Deletes objects with given IDs from both local repository and Datadog"

    def delete(*ids)
      CLI::Delete.new.run
    end

    desc "sync", "Pushes the changes to Datadog"
    long_desc <<-D
      Performs git diff between the HEAD and last deployed SHA to get the changes,
      then accordingly either deletes or pushes objects to Datadog.
    D

    def sync
      CLI::Push.new.sync_changes
    end

    desc "push [IDs]", "Hard pushes objects to Datadog"
    long_desc <<-D
      Pushes objects to Datadog. You can provide list of IDs to scope it to certain objects,
      otherwise it will push all local objects to Datadog. The changes in Datadog that are not in
      the repository will be overridden. This action does not delete anything.
      IDs is a space separated list of item IDs.
    D

    def push(*ids)
      CLI::Push.new.push_all(ids)
    end

    desc "mute IDs", "Mutes given monitors indefinitely"
    long_desc <<-D
      IDs is a space separated list of item IDs.
    D

    def mute(*ids)
      CLI::Mute.new(options.dup, ids).run
    end

    desc "unmute IDs", "Unmutes given monitors"
    long_desc <<-D
      IDs is a space separated list of item IDs.
    D

    def unmute(*ids)
      CLI::Unmute.new(options.dup, ids).run
    end

    desc "edit ID", "Edits given item in Datadog UI"

    def edit(id)
      CLI::Edit.new(options.dup, id).run
    end
  end
end

