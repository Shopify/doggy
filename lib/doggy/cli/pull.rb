# encoding: utf-8

module Doggy
  class CLI::Pull
    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      @local_resources = Doggy::Model.all_local_resources
      if @ids.empty?
        @local_resources.each do |local_resource|
          if remote_resource = local_resource.class.find(local_resource.id)
            remote_resource.path = local_resource.path
            remote_resource.save_local
          else
            local_resource.destroy_local
          end
        end
      else
        @ids.each { |id| pull_by_id(id.to_i) }
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
  end
end
