# encoding: utf-8

module Doggy
  class CLI::Delete
    def run(ids)
      Doggy::Model.all_local_resources.each do |resource|
        next unless ids.include?(resource.id.to_s)
        Doggy.ui.say("Deleting #{resource.path}, with id #{resource.id}")
        resp = resource.destroy
        if resp['errors']
          Doggy.ui.error("Could not delete. Error: #{resp['errors']}. Skipping")
        else
          resource.destroy_local
        end
      end
    end
  end
end
