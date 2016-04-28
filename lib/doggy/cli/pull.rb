# encoding: utf-8

module Doggy
  class CLI::Pull
    def initialize(options, ids_or_names)
      @options      = options
      @ids_or_names = ids_or_names
    end

    def run
      if @ids_or_names.empty?
        pull_resources('dashboards', Models::Dashboard) if !@options.any? || @options['dashboards']
        pull_resources('monitors',   Models::Monitor)   if !@options.any? || @options['monitors']
        pull_resources('screens',    Models::Screen)    if !@options.any? || @options['screens']
        return
      end

      @ids_or_names.each do |id_or_name|
        @local_resources = Doggy::Model.all_local_resources
        if id_or_name =~ /^\d+$/
          pull_by_id(id_or_name.to_i)
        else
          pull_by_file(id_or_name)
        end
      end
    end

  private

    def pull_by_id(id)
      local_resource = @local_resources.find { |l| l.id == id }
      if !local_resource
        remote_resource = [Models::Dashboard, Models::Monitor, Models::Screen].map do |klass|
          klass.find(id)
        end.compact.first

        remote_resource.save_local
      else
        remote_resource = local_resource.class.find(local_resource.id)
        remote_resource.path = local_resource.path
        remote_resource.save_local
      end
    end

    def pull_by_file(file)
      resolved_path = Doggy.resolve_path(file)
      local_resource = @local_resources.find { |l| l.path == resolved_path }

      remote_resource = local_resource.class.find(local_resource.id)
      remote_resource.path = local_resource.path
      remote_resource.save_local
    end

    def pull_resources(name, klass)
      Doggy.ui.say "Pulling #{ name }..."
      local_resources  = klass.all_local
      remote_resources = klass.all

      klass.assign_paths(remote_resources, local_resources)
      remote_resources.each(&:save_local)
    end
  end
end

