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
      local_resources = @local_resources.find_all { |l| l.id == id }

      remote_resources = [Models::Dashboard, Models::Monitor, Models::Screen].map do |klass|
        klass.find(id)
      end.compact

      if local_resources.size != remote_resources.size
        normalized_remote_resources = remote_resources.map { |remote_resource| [ remote_resource.class.name, remote_resource.id ] }
        normalized_local_resources = local_resources.map { |local_resource| [ local_resource.class.name, local_resource.id ] }
        normalized_resource_diff = Hash[normalized_remote_resources - normalized_local_resources]

        # Here we traverse `remote_resources` to find remote resource with matching class name and id.
        # We cannot subtract `local_resources` from `remote_resources` because those are different kind of objects.
        remote_resources_to_be_saved = normalized_resource_diff.map do |klass, normalized_resource_id|
          remote_resources.find do |rr|
            rr.class.name == klass && rr.id == normalized_resource_id
          end
        end

        remote_resources_to_be_saved.each(&:save_local)
      else
        local_resources.each do |local_resource|
          remote_resource = local_resource.class.find(local_resource.id)
          remote_resource.path = local_resource.path
          remote_resource.save_local
        end
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

      ids = local_resources.map(&:id) - remote_resources.map(&:id)
      local_resources.each do |local_resource|
        local_resource.destroy_local if ids.include?(local_resource.id)
      end
    end
  end
end

