# encoding: utf-8

module Doggy
  class CLI::Pull
    def initialize(options)
      @options = options
    end

    def run
      pull_resources('dashboards', Models::Dashboard) if should_pull?('dashboards')
      pull_resources('monitors',   Models::Monitor)   if should_pull?('monitors')
      pull_resources('screens',    Models::Screen)    if should_pull?('screens')
    end

  private

    def should_pull?(resource)
      @options.empty? || @options[resource]
    end

    def pull_resources(name, klass)
      Doggy.ui.say "Pulling #{ name }"
      local_resources  = klass.all_local
      remote_resources = klass.all

      klass.assign_paths(remote_resources, local_resources)
      remote_resources.each(&:save_local)
    end
  end
end

