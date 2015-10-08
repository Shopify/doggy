# encoding: utf-8

module Doggy
  class CLI::Pull
    def initialize(ids:, options:)
      @ids = ids
      @options = options
      @updated_by_last_action = false
    end

    def run
      pull_resources('dashboards', Models::Dashboard, @ids) if should_pull?('dashboards')
      pull_resources('monitors',   Models::Monitor, @ids)   if should_pull?('monitors')
      pull_resources('screens',    Models::Screen, @ids)    if should_pull?('screens')

      Doggy.ui.say "Nothing to pull: please specify object ID or use '-a' to pull everything" unless @updated_by_last_action
    end

  private

    def should_pull?(resource)
      !@options.empty? || @options[resource] || @ids.any?
    end

    def pull_resources(name, klass, ids)
      if ids.any?
        Doggy.ui.say "Pulling #{ name }: #{ids.join(', ')}"
        remote_resources = klass.all.find_all { |m| ids.include?(m.id.to_s) }
      else
        Doggy.ui.say "Pulling #{ name }"
        remote_resources = klass.all
      end
      local_resources  = klass.all_local
      klass.assign_paths(remote_resources, local_resources)
      @updated_by_last_action = true
      remote_resources.each(&:save_local)
    end
  end
end

