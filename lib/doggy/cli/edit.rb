# frozen_string_literal: true

module Doggy
  class CLI::Edit
    def initialize(options, param)
      @options = options
      @param   = param
    end

    def run
      resource = Doggy::Model.find_local(@param)
      return Doggy.ui.error("Could not find resource with #{@param}") unless resource

      forked_resource = fork(resource)
      system("open '#{forked_resource.human_edit_url}'")
      wait_for_edit

      new_resource = Doggy::Model.infer_type(resource.attributes).find(forked_resource.id)
      new_resource.id = resource.id
      if new_resource.is_a?(Doggy::Models::Dashboard)
        new_resource.title = resource.title
        new_resource.description = resource.description
      elsif new_resource.is_a?(Doggy::Models::Monitor)
        new_resource.name = resource.name
      end
      new_resource.path = resource.path
      new_resource.save_local

      forked_resource.destroy
    end

    private

    def wait_for_edit
      Doggy.ui.say("run, rabbit run / dig that hole, forget the sun / and when at last the work is done / don't sit down / it's time to dig another one") until Doggy.ui.yes?('Are you done editing?(Y/N)')
    end

    def fork(resource)
      forked_resource = resource.class.new(resource.attributes.except("id")) # TODO: Except "url" too
      forked_resource.path = resource.path # TODO: should not be forked
      forked_resource.refute_read_only!

      if /dashboard/.match?(resource.class.to_s.downcase)
        forked_resource.title = "[#{Doggy.random_word}] #{resource.title}"
      elsif /monitor/.match?(resource.class.to_s.downcase)
        forked_resource.name = "[#{Doggy.random_word}] #{resource.name}"
      else
        raise StandardError, 'Unknown resource type, cannot edit.'
      end

      forked_resource.save
      forked_resource
    end
  end
end
