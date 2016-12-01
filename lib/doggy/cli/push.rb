# encoding: utf-8

module Doggy
  class CLI::Push
    WARNING_MESSAGE = "You are about to force push all the objects. "\
      "This will override changes in Datadog if they have not been sycned to the dog repository. "\
      "Do you want to proceed?(Y/N)"

    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      if !@ids.empty? || @options['all_objects'] && (warning_accepted = Doggy.ui.yes?(WARNING_MESSAGE))
        Doggy::Model.all_local_resources.each do |resource|
          next unless @ids.include?(resource.id.to_s) && @options['all_objects']
          Doggy.ui.say "Pushing #{ resource.path }"
          resource.ensure_read_only!
          resource.save
        end
      elsif !warning_accepted
        Doggy.ui.say "Operation cancelled"
        return
      else
        push_resources('dashboards', Models::Dashboard) unless @options['no-dashboards']
        push_resources('monitors', Models::Monitor) unless @options['no-monitors']
        push_resources('screens', Models::Screen) unless @options['no-screens']
      end

      Doggy::Model.emit_shipit_deployment
    end

    private

    def push_resources(name, klass)
      Doggy.ui.say "Pushing #{ name }"
      local_resources = klass.all_local
      Doggy.ui.say "#{ local_resources.size } objects to push"
      local_resources.each do |resource|
        if resource.is_deleted
          Doggy.ui.say "Deleting #{resource.path}, with id = #{resource.id}"
          resource.destroy
        else
          Doggy.ui.say "Saving #{resource.path}, with id = #{resource.id}"
          resource.ensure_read_only!
          resource.save
        end
      end
    end
  end
end
