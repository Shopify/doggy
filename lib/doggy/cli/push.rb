# encoding: utf-8

module Doggy
  class CLI::Push
    WARNING_MESSAGE = "You are about to force push all the objects. "\
      "This will override changes in Datadog if they have not been sycned to the dog repository. "\
      "Do you want to proceed?(Y/N)"

    def initialize(options)
      @options = options
    end

    def run
      if @options['all_objects'] && !Doggy.ui.yes?(WARNING_MESSAGE)
        Doggy.ui.say "Operation cancelled"
        return
      end

      push_resources('dashboards', Models::Dashboard) if @options['dashboards']
      push_resources('monitors',   Models::Monitor)   if @options['monitors']
      push_resources('screens',    Models::Screen)    if @options['screens']

      Doggy::Model.emit_shipit_deployment
    end

  private

    def push_resources(name, klass)
      Doggy.ui.say "Pushing #{ name }"
      local_resources = klass.all_local(only_changed: !@options['all_objects'])
      local_resources.each(&:ensure_read_only!)
      Doggy.ui.say "#{ local_resources.size } objects to push"
      local_resources.each(&:save)
    end
  end
end

