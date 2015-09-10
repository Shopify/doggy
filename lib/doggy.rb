require 'fileutils'
require 'pathname'
require 'json'
require 'yaml'
require 'dogapi'

require 'doggy/version'
require 'doggy/client'
require 'doggy/worker'
require 'doggy/serializer/json'
require 'doggy/serializer/yaml'
require 'doggy/model/dash'
require 'doggy/model/monitor'
require 'doggy/model/screen'

module Doggy
  DOG_SKIP_REGEX = /\[dog\s+skip\]/i.freeze
  DEFAULT_SERIALIZER_CLASS = Doggy::Serializer::Json
  MAX_TRIES = 5

  class DoggyError < StandardError
    def self.status_code(code)
      define_method(:status_code) { code }
    end
  end

  class InvalidOption < DoggyError; status_code(15); end
  class InvalidItemType < DoggyError; status_code(10); end

  class << self
    # @option arguments [Constant] :serializer A specific serializer class to use, will be initialized by doggy and passed the object instance
    def serializer(options = {})
      @serializer ||= options[:serializer] ? options[:serializer] : DEFAULT_SERIALIZER_CLASS
    end

    def client
      Doggy::Client.new
    end

    # Absolute path of where alerts are stored on the filesystem.
    #
    # @return [Pathname]
    def alerts_path
      @alerts_path ||= Pathname.new('alerts').expand_path(Dir.pwd).expand_path.tap { |path| FileUtils.mkdir_p(path) }
    end

    # Absolute path of where dashes are stored on the filesystem.
    #
    # @return [Pathname]
    def dashes_path
      @dashes_path ||=  Pathname.new('dashes').expand_path(Dir.pwd).expand_path.tap { |path| FileUtils.mkdir_p(path) }
    end

    # Absolute path of where screens are stored on the filesystem.
    #
    # @return [Pathname]
    def screens_path
      @screens_path ||= Pathname.new('screens').expand_path(Dir.pwd).expand_path.tap { |path| FileUtils.mkdir_p(path) }
    end

    # Cleans up directory
    def clean_dir(dir)
      Dir.foreach(dir) { |f| fn = File.join(dir, f); File.delete(fn) if f != '.' && f != '..'}
    end

    def all_local_items
      @all_local_items ||= Dir[Doggy.dashes_path.join('**/*'), Doggy.alerts_path.join('**/*'), Doggy.screens_path.join('**/*')].inject({}) { |memo, file| memo.merge load_item(f) }
    end

    def load_item(f)
      filetype = File.extname(f)

      item = case filetype
      when '.yaml', '.yml' then Doggy::Serializer::Yaml.load(File.read(f))
      when '.json'         then Doggy::Serializer::Json.load(File.read(f))
      else                      raise InvalidItemType
      end

      { [ determine_type(item), item['id'] ] => item }
    end

    def determine_type(item)
      return 'dash'    if item['graphs']
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

    def with_retry(times: MAX_TRIES, reraise: false)
      tries = 0
      while tries < times
        begin
          yield
          break
        rescue => e
          error "Caught error in create_record! attempt #{tries}..."
          error "#{e.class.name}: #{e.message}"
          error "#{e.backtrace.join("\n")}"
          tries += 1

          raise e if tries >= times && reraise
        end
      end
    end

    def current_version
      now = Time.now.to_i
      month_ago = now - 3600 * 24 * 30
      events = Doggy.client.dog.stream(month_ago, now, tags: %w(audit shipit))[1]['events']

      events[0]['text'] # most recetly deployed SHA
    rescue => e
      puts "Exception: #{e.message}"
    end

    def all_remote_dashes
      @all_remote_dashes ||= Doggy.client.dog.get_dashboards[1]['dashes'].inject({}) do |memo, dash|
        memo.merge([ 'dash', dash['id'] ] => dash)
      end
    end

    def all_remote_monitors
      @all_remote_monitors ||= Doggy.client.dog.get_all_monitors[1].inject({}) do |memo, monitor|
        memo.merge([ 'monitor', monitor['id'] ] => monitor)
      end
    end
  end
end
