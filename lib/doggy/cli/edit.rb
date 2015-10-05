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
        system("open '#{ resource.human_edit_url }'")
        while !Doggy.ui.yes?('Are you done editing?') do
          Doggy.ui.say "run, rabbit run / dig that hole, forget the sun / and when at last the work is done / don't sit down / it's time to dig another one"
        end

        new_resource      = resource.class.find(resource.id)
        new_resource.path = resource.path
        new_resource.save_local
      end
    end

  private

    def resource_by_param
      resources  = Doggy::Models::Dashboard.all_local
      resources += Doggy::Models::Monitor.all_local
      resources += Doggy::Models::Screen.all_local

      if @param =~ /^[0-9]+$/ then
        id = @param.to_i
        return resources.find { |res| res.id == id }
      else
        full_path = File.expand_path(@param, Dir.pwd)
        return resources.find { |res| res.path == full_path }
      end
    end
  end
end

