# encoding: utf-8

module Doggy
  class CLI::Fork
    def initialize(options, param)
      @options = options
      @param   = param
    end

    def run
      resource = resource_by_param
      resource.read_only = false
      return Doggy.ui.error("Could not find resource with #{ @param }") unless resource

      Dir.chdir(File.dirname(resource.path)) do
        fork(resource).save_local
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
        return resources.find { |res| res.path == full_path }
      end
    end

    def fork(resource)
      forked_resource = resource.dup
      resource_as_string =  resource.to_hash.to_s

      # Replace any substring with matching string with the new one
      @options[:variables].each do |orig_val, new_val|
        resource_as_string.gsub!(orig_val, new_val)
      end
      forked_resource = resource.class.new(eval(resource_as_string))
      forked_resource.id = nil

      forked_resource.save
      forked_resource
    end
  end
end

