require 'fileutils'
require 'pathname'
require 'json'
require 'yaml'
require 'dogapi'

require 'doggy/friendly_errors'

require 'doggy/version'
require 'doggy/errors'
require 'doggy/shared_helpers'
require 'doggy/client'
require 'doggy/worker'
require 'doggy/definition'
require 'doggy/dsl'
require 'doggy/serializer/json'
require 'doggy/serializer/yaml'
require 'doggy/model/dash'
require 'doggy/model/monitor'
require 'doggy/model/screen'

module Doggy
  DOG_SKIP_REGEX = /😱|:scream:/i.freeze
  MANAGED_BY_DOGGY_REGEX = /🐶|\:dog\:/i.freeze
  DEFAULT_SERIALIZER_CLASS = Doggy::Serializer::Json

  class << self
    # @option arguments [Constant] :serializer A specific serializer class to use, will be initialized by doggy and passed the object instance
    def serializer(options = {})
      @serializer ||= options[:serializer] ? options[:serializer] : DEFAULT_SERIALIZER_CLASS
    end

    def client
      Doggy::Client.new
    end

    def objects_path
      @objects_path ||= Pathname.new('objects').expand_path(Dir.pwd).expand_path.tap { |path| FileUtils.mkdir_p(path) }
    end

    def load_item(f)
      item = case File.extname(f)
      when '.yaml', '.yml' then Doggy::Serializer::Yaml.load(File.read(f))
      when '.json'         then Doggy::Serializer::Json.load(File.read(f))
      when '.rb'           then Doggy::Dsl.evaluate(f).obj
      else                      raise InvalidItemType
      end

      # Hackery to support legacy dash format
      {
        [
          determine_type(item), item['id'] || item['dash']['id']
        ] => item['dash'] ? item['dash'] : item
      }
    end

    def edit(id)
      object = all_local_items.detect { |(type, object_id), object| object_id.to_s == id }
      if object && object[0] && object[0][0] && type = object[0][0].sub(/^[a-z\d]*/) { $&.capitalize }
        Object.const_get("Doggy::#{type}").edit(id)
      end
    end

    def determine_type(item)
      return 'dash'    if item['graphs'] || item['dash']
      return 'monitor' if item['message']
      return 'screen'  if item['board_title']
      raise InvalidItemType
    end

    def emit_shipit_deployment
      Doggy.client.dog.emit_event(
        Dogapi::Event.new(ENV['REVISION'], msg_title: "ShipIt Deployment by #{ENV['USER']}", tags: %w(audit shipit), source_type_name: 'shipit')
      )
    rescue => e
      puts "Exception: #{e.message}"
    end

    def current_sha
      now = Time.now.to_i
      month_ago = now - 3600 * 24 * 30
      events = Doggy.client.dog.stream(month_ago, now, tags: %w(audit shipit))[1]['events']

      events[0]['text'] # most recetly deployed SHA
    rescue => e
      puts "Exception: #{e.message}"
    end

    def all_local_items
      @all_local_items ||= Dir[Doggy.objects_path.join('**/*')].inject({}) do |memo, file|
        next if File.directory?(file)
        memo.merge!(load_item(file))
      end
    end
  end
end
