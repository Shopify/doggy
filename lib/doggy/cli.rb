# encoding: utf-8

require "thor"

module Doggy
  class CLI < Thor
    include Thor::Actions

    map %w(--version -v) => :__print_version

    desc '--version, -v', 'print the version'
    def __print_version
      puts Doggy::VERSION
    end

    desc "pull [IDs]", "Pulls objects from Datadog"

    def pull(*ids)
      CLI::Pull.new(options.dup, ids).run
    end

    desc "delete IDs", "Deletes objects with given IDs from both local repository and Datadog"

    def delete(*ids)
      CLI::Delete.new.run(ids)
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

    desc 'mute IDs [--duration DURATION]', 'Mutes given monitors indefinitely or for the specific duration'
    long_desc <<-D
      IDs is a space separated list of item IDs.
      If `--duration` is not given, item will be muted indefinitely.
    D

    method_option 'duration', type: :string, desc: 'Mute only for the given period of time.'
    method_option 'scope', type: :string, desc: 'The scope to apply the mute to.'

    def mute(*ids)
      CLI::Mute.new(options.dup, ids).run
    end

    desc 'unmute IDs', 'Unmutes given monitors'
    long_desc <<-D
      IDs is a space separated list of item IDs.
    D

    method_option 'scope', type: :string, desc: 'The scope to apply the unmute to.'
    method_option 'all_scopes', type: :boolean, default: false, desc: 'Clear muting across all scopes.'

    def unmute(*ids)
      CLI::Unmute.new(options.dup, ids).run
    end

    desc "edit ID", "Edits given item in Datadog UI"

    def edit(id)
      CLI::Edit.new(options.dup, id).run
    end

    desc "fork OBJECT_ID", "Forks existing object to new one"
    long_desc <<-D
      Edits an object
    D

    method_option :variables, :type => :hash, :default => {}

    def fork(id)
      CLI::Fork.new(options.dup, id).run
    end
  end
end

