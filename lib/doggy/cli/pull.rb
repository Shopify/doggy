# frozen_string_literal: true

require 'parallel'

module Doggy
  class CLI::Pull
    def initialize(options, ids)
      @options = options
      @ids = ids
    end

    def run
      @local_resources = Doggy::Model.all_local_resources
      id_migration_mapping = {}

      if @ids.empty?
        Parallel.each(@local_resources) do |local_resource|
          remote_resource = local_resource.class.find(local_resource.id)
          if (new_id = remote_resource&.attributes&.dig("dash", "new_id")) || (new_id = remote_resource&.attributes&.dig("new_id"))
            id_migration_mapping[local_resource.id.to_s] = local_resource.class.find(new_id)
          end

          if remote_resource
            if id_migration_mapping.key?(local_resource.id)
              remote_resource.attributes = id_migration_mapping[local_resource.id].attributes
            end

            remote_resource.path = local_resource.path
            remote_resource.save_local
          else
            local_resource.destroy_local
          end
        end
      else
        @ids.each { |id| pull_by_id(id.to_s) }
      end
    end

    private

    def pull_by_id(id)
      local_resources = @local_resources.find_all { |l| l.id.to_s == id.to_s }
      id_migration_mapping = {}

      remote_resources = [Models::Dashboard, Models::Monitor].map do |klass|
        result = klass.find(id.to_s)
        if (new_id = result&.attributes&.dig("dash", "new_id")) || (new_id = result&.attributes&.dig("new_id"))
          id_migration_mapping[id.to_s] = klass.find(new_id)
        end
        result
      end.compact

      if local_resources.size != remote_resources.size
        normalized_remote_resources = remote_resources.map { |remote_resource| [remote_resource.class.name, remote_resource.id.to_s] }
        normalized_local_resources = local_resources.map { |local_resource| [local_resource.class.name, local_resource.id.to_s] }
        normalized_resource_diff = Hash[normalized_remote_resources - normalized_local_resources]

        # Here we traverse `remote_resources` to find remote resource with matching class name and id.
        # We cannot subtract `local_resources` from `remote_resources` because those are different kind of objects.
        remote_resources_to_be_saved = normalized_resource_diff.map do |klass, normalized_resource_id|
          remote_resources.find do |rr|
            rr.class.name == klass && rr.id.to_s == normalized_resource_id.to_s
          end
        end

        remote_resources_to_be_saved.each(&:save_local)
      else
        local_resources.each do |local_resource|
          remote_resource = local_resource.class.find(local_resource.id)

          if id_migration_mapping.key?(local_resource.id)
            remote_resource.attributes = id_migration_mapping[local_resource.id].attributes
          end

          remote_resource.path = local_resource.path
          remote_resource.save_local
        end
      end
    end
  end
end
