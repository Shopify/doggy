# frozen_string_literal: true

module Doggy
  class CLI::Push
    WARNING_MESSAGE = "You are about to force push all the objects. "\
      "This will override changes in Datadog if they have not been synced to the dog repository. "\
      "Do you want to proceed? (Y/N)"

    def sync_changes
      changed_resources = Doggy::Model.changed_resources
      Doggy.ui.say("Syncing #{changed_resources.size} objects to Datadog...")
      changed_resources.each do |resource|
        if resource.is_deleted
          Doggy.ui.say("Deleting #{resource.path}, with id = #{resource.id}")
          resp = resource.destroy
          Doggy.ui.say("Response: #{resp.inspect}")
        else
          Doggy.ui.say("Saving #{resource.path}, with id = #{resource.id}")
          resource.ensure_read_only!
          resource.save
        end
      end
      Doggy::Model.emit_shipit_deployment
    end

    def push_all(ids)
      if ids.empty? && !Doggy.ui.yes?(WARNING_MESSAGE)
        Doggy.ui.say('Operation cancelled')
        return
      end
      Doggy::Model.all_local_resources.each do |resource|
        next if ids.any? && !ids.include?(resource.id.to_s)
        Doggy.ui.say("Pushing #{resource.path}, with id #{resource.id}")
        resource.ensure_read_only!
        resource.save
      end
    end
  end
end
