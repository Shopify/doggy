# encoding: utf-8

module Doggy
  class CLI::Push
    def initialize(options)
      @options = options
    end

    def run
      push_resources('dashboards', Models::Dashboard) if @options['dashboards']
      push_resources('monitors',   Models::Monitor)   if @options['monitors']
      push_resources('screens',    Models::Screen)    if @options['screens']

      Doggy::Model.emit_shipit_deployment
    end

  private

    def push_resources(name, klass)
      Doggy.ui.say "Pushing #{ name }"
      local_resources = klass.all_local(only_changed: !@options['all_objects'])
      local_resources.each(&:save)
    end
  end
end

