# frozen_string_literal: true

require "pathname"
require "net/http"
require "rugged"

require "doggy/hash_sort"
require "doggy/cli"
require "doggy/cli/edit"
require "doggy/cli/mute"
require "doggy/cli/pull"
require "doggy/cli/push"
require "doggy/cli/unmute"
require "doggy/cli/delete"
require "doggy/model"
require "doggy/models/dashboard"
require "doggy/models/monitor"

module Doggy
  DOG_SKIP_REGEX         = /😱|:scream:/i.freeze
  MANAGED_BY_DOGGY_REGEX = /🐶|:dog:/i.freeze

  class DoggyError < StandardError; end

  extend self

  def random_word
    (0...12).map { (97 + rand(26)).chr }.join
  end

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

    while current_dir != '/'
      if File.exist?(File.join(current_dir, 'Gemfile'))
        return Pathname.new(current_dir)
      else
        current_dir = File.expand_path('../', current_dir)
      end
    end
  end

  def base_human_url
    ENV['DATADOG_BASE_HUMAN_URL'] || secrets['datadog_base_human_url'] || 'app.datadoghq.com'
  end

  def api_key
    ENV['DATADOG_API_KEY'] || secrets['datadog_api_key']
  end

  def application_key
    ENV['DATADOG_APP_KEY'] || secrets['datadog_app_key']
  end

  def resolve_path(path)
    path     = Pathname.new(path)
    curr_dir = Pathname.new(Dir.pwd)
    resolved = object_root.relative_path_from(curr_dir)

    (curr_dir.expand_path(resolved + path) + path).to_s
  end

  protected

  def secrets
    @secrets ||= begin
                   raw = File.read(repo_root.join('secrets.json'))
                   JSON.parse(raw)
                 end
  end
end
