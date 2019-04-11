# encoding: utf-8
# frozen_string_literal: true

module Doggy
  module Models
    class Screen < Doggy::Model
      attribute :id,                 Integer
      attribute :board_title,        String

      attribute :board_bgtype,       String
      attribute :templated,          Boolean
      attribute :template_variables, Array[Hash]
      attribute :widgets,            Array[Hash]
      attribute :height,             String
      attribute :width,              String
      attribute :read_only,          Boolean

      def prefix
        'screen'
      end

      def ensure_read_only!
        self.read_only = true
      end

      def refute_read_only!
        self.read_only = false
      end

      def self.resource_url(id = nil)
        ["https://app.datadoghq.com/api/v1/screen", id].compact.join("/")
      end

      def managed?
        !(board_title =~ Doggy::DOG_SKIP_REGEX)
      end

      def ensure_managed_emoji!
        return unless managed?
        return if board_title =~ /\xF0\x9F\x90\xB6/
        self.board_title += " \xF0\x9F\x90\xB6"
      end

      def human_url
        "https://#{Doggy.base_human_url}/screen/#{id}"
      end

      # Screens don't have a direct edit URL
      alias_method :human_edit_url, :human_url
    end # Screen
  end # Models
end # Doggy
