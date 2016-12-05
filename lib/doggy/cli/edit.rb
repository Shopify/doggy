# encoding: utf-8

module Doggy
  class CLI::Edit
    def initialize(options, param)
      @options = options
      @param   = param
    end

    def run
      resource = Doggy::Model.find_local(@param)
      return Doggy.ui.error("Could not find resource with #{ @param }") unless resource

      forked_resource = fork(resource)
      system("open '#{ forked_resource.human_edit_url }'")
      wait_for_edit

      new_resource = Doggy::Model.infer_type(resource.attributes).find(forked_resource.id)
      new_resource.id = resource.id
      if new_resource.is_a?(Doggy::Models::Dashboard)
        new_resource.title = resource.title
        new_resource.description = resource.description
      elsif new_resource.is_a?(Doggy::Models::Monitor)
        new_resource.name = resource.name
      elsif new_resource.is_a?(Doggy::Models::Screen)
        new_resource.board_title = resource.board_title
      end
      new_resource.path = resource.path
      new_resource.save_local

      forked_resource.destroy
    end

    private

    def wait_for_edit
      while !Doggy.ui.yes?('Are you done editing?(Y/N)') do
        Doggy.ui.say "run, rabbit run / dig that hole, forget the sun / and when at last the work is done / don't sit down / it's time to dig another one"
      end
    end

    def fork(resource)
      salt = random_word
      forked_resource = resource.dup
      forked_resource.id = nil
      forked_resource.refute_read_only!
      if resource.class.to_s.downcase =~ /dashboard/
        forked_resource.title = "[#{ salt }] " + forked_resource.title
        forked_resource.description = "[fork of #{ resource.id }] " + forked_resource.title
      elsif resource.class.to_s.downcase =~ /screen/
        forked_resource.board_title = "[#{ salt }] " + forked_resource.board_title
      elsif resource.class.to_s.downcase =~ /monitor/
        forked_resource.name = "[#{ salt }] " + forked_resource.name
      else
        raise StandardError.new('Unknown resource type, cannot edit.')
      end
      forked_resource.save
      forked_resource
    end

    def random_word
      (0...12).map { (65 + rand(26)).chr.downcase }.join
    end
  end
end
