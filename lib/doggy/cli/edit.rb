# encoding: utf-8

module Doggy
  class CLI::Edit
    def initialize(options, param)
      @options = options
      @param   = param
    end

    def run
      resource = resource_by_param
      return Doggy.ui.error("Could not find resource with #{ @param }") unless resource

      Dir.chdir(File.dirname(resource.path)) do
        if resource.class.to_s.downcase =~ /dashboard/
          forked_resource = fork(resource)
          system("open '#{ forked_resource.human_edit_url }'")

          wait_for_edit

          new_resource             = Doggy::Models::Dashboard.find(forked_resource.id)
          new_resource.id          = resource.id
          new_resource.title       = resource.title
          new_resource.description = resource.description
          new_resource.path        = resource.path
          new_resource.save_local

          forked_resource.destroy
        else
          system("open '#{ resource.human_edit_url }'")

          wait_for_edit

          new_resource      = resource.class.find(resource.id)
          new_resource.path = resource.path
          new_resource.save_local
        end
      end
    end

  private

    def resource_by_param
      resources  = Doggy::Models::Dashboard.all_local
      resources += Doggy::Models::Monitor.all_local
      resources += Doggy::Models::Screen.all_local
# raise 1.inspect
      if @param =~ /^[0-9]+$/ then
        id = @param.to_i
        return resources.find { |res| res.id == id }
      elsif @param =~ /^http/ then
        id = case @param
          when /com\/dash/     then Integer(@param[/dash\/(\d+)/i, 1])
          when /com\/screen/   then Integer(@param[/screen\/(\d+)/i, 1])
          when /com\/monitors/ then Integer(@param[/monitors#(\d+)/i, 1])
          else raise StandardError.new('Unknown resource type, cannot edit.')
          end
        return resources.find { |res| res.id == id }
      else
        full_path = File.expand_path(@param.gsub('objects/', ''), Doggy.object_root)
        # raise full_path.inspect
        return resources.find { |res| res.path == full_path }
      end
    end

    def wait_for_edit
      while !Doggy.ui.yes?('Are you done editing?') do
        Doggy.ui.say "run, rabbit run / dig that hole, forget the sun / and when at last the work is done / don't sit down / it's time to dig another one"
      end
    end

    def fork(resource)
      salt = (0...12).map { (65 + rand(26)).chr.downcase }.join

      forked_resource = resource.dup
      forked_resource.id = nil
      forked_resource.title = "[#{ salt }] " + forked_resource.title
      forked_resource.description = "[fork of #{ resource.id }] " + forked_resource.title
      forked_resource.save
      forked_resource
    end
  end
end

