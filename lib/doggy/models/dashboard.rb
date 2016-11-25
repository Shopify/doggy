# encoding: utf-8

module Doggy
  module Models
    class Dashboard < Doggy::Model
      self.root = 'dash'

      attribute :id,          Integer
      attribute :title,       String
      attribute :description, String

      attribute :graphs,             Array[Hash]
      attribute :template_variables, Array[Hash]
      attribute :read_only,          Boolean

      def prefix
        'dash'
      end

      def ensure_read_only!
        self.read_only = true
      end

      def self.resource_url(id = nil)
        "https://app.datadoghq.com/api/v1/dash".tap do |base_url|
          base_url << "/#{ id }" if id
        end
      end

      def managed?
        !(title =~ Doggy::DOG_SKIP_REGEX)
      end

      def ensure_managed_emoji!
        return unless managed?
        return if self.title =~ /\xF0\x9F\x90\xB6/
        self.title += " \xF0\x9F\x90\xB6"
      end

      def human_url
        "https://app.datadoghq.com/dash/#{ id }"
      end

      # Dashboards don't have a direct edit URL
      alias_method :human_edit_url, :human_url
    end # Dashboard
  end # Models
end # Doggy

