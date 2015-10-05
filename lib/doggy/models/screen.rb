# encoding: utf-8

module Doggy
  module Models
    class Screen < Doggy::Model
      attribute :id,          Integer
      attribute :board_title, String

      attribute :board_bgtype, String
      attribute :templated,    Boolean
      attribute :widgets,      Array[Hash]
      attribute :height,       String
      attribute :width,        String

      def self.resource_url(id = nil)
        "https://app.datadoghq.com/api/v1/screen".tap do |base_url|
          base_url << "/#{ id }" if id
        end
      end

      def managed?
        !(board_title =~ Doggy::DOG_SKIP_REGEX)
      end

      def ensure_managed_emoji!
        return unless managed?
        self.board_title += " \xF0\x9F\x90\xB6"
      end

      def human_url
        "https://app.datadoghq.com/screen/#{ id }"
      end

      # Screens don't have a direct edit URL
      alias_method :human_edit_url, :human_url
    end # Screen
  end # Models
end # Doggy

