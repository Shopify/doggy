# encoding: utf-8

module Doggy
  class CLI::Push
    def initialize(options)
      @options = options
    end

    def run
      push_resources('dashboards', Models::Dashboard) if should_push?('dashboards')
      push_resources('monitors',   Models::Monitor)   if should_push?('monitors')
      push_resources('screens',    Models::Screen)    if should_push?('screens')

      Doggy::Model.emit_shipit_deployment
    end

  private

    def should_push?(resource)
      @options.empty? || @options[resource]
    end

    def push_resources(name, klass)
      Doggy.ui.say "Pushing #{ name }"
      local_resources = klass.all_local(only_changed: true)
      local_resources.each(&:save)
    end
  end
end

