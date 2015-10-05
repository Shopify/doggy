# encoding: utf-8

require "pathname"
require "net/http"

require "doggy/cli"
require "doggy/cli/edit"
require "doggy/cli/mute"
require "doggy/cli/pull"
require "doggy/cli/push"
require "doggy/cli/unmute"
require "doggy/model"
require "doggy/models/dashboard"
require "doggy/models/monitor"
require "doggy/models/screen"
require "doggy/version"

module Doggy
  DOG_SKIP_REGEX         = /\xF0\x9F\x98\xB1|:scream:/i.freeze
  MANAGED_BY_DOGGY_REGEX = /\xF0\x9F\x90\xB6|:dog:/i.freeze

  extend self

  def ui
    (defined?(@ui) && @ui) || (self.ui = Thor::Shell::Color.new)
  end

  def ui=(ui)
    @ui = ui
  end

  def object_root
    @object_root ||= Pathname.new('objects').expand_path(repo_root)
  end

  def repo_root
    # TODO: Raise error when root can't be found
    current_dir = Dir.pwd

    while current_dir != '/' do
      if File.exists?(File.join(current_dir, 'Gemfile')) then
        return Pathname.new(current_dir)
      else
        current_dir = File.expand_path('../', current_dir)
      end
    end
  end

  def api_key
    ENV['DATADOG_API_KEY'] || secrets['datadog_api_key']
  end

  def application_key
    ENV['DATADOG_APP_KEY'] || secrets['datadog_app_key']
  end

protected

  def secrets
    @secrets ||= begin
                   raw = File.read(repo_root.join('secrets.json'))
                   JSON.parse(raw)
                 end
  end
end # Doggy
