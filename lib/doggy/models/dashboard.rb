# frozen_string_literal: true

module Doggy
  module Models
    class Dashboard < Doggy::Model
      def id
        attributes["id"]
      end

      def id=(v)
        attributes["id"] = v
      end

      def title
        attributes["title"]
      end

      def title=(v)
        attributes["title"] = v
      end

      def description
        attributes["description"]
      end

      def description=(v)
        attributes["description"] = v
      end

      def read_only
        if attributes["widgets"]
          attributes["is_read_only"]
        else
          attributes["read_only"]
        end
      end

      def read_only=(v)
        if attributes["widgets"]
          attributes["is_read_only"] = v
        else
          attributes["read_only"] = v
        end
      end

      def prefix
        'dashboard'
      end

      def ensure_read_only!
        self.read_only = true
      end

      def refute_read_only!
        self.read_only = false
      end

      def self.resource_url(id = nil, kind = "dashboard")
        ["https://app.datadoghq.com/api/v1/#{kind}", id].compact.join("/")
      end

      def managed?
        title !~ Doggy::DOG_SKIP_REGEX
      end

      def ensure_managed_emoji!
        return unless managed?
        return if title =~ /🐶/
        self.title = "#{title} 🐶"
      end

      def human_url
        "https://#{Doggy.base_human_url}/dashboard/#{id}"
      end

      # Dashboards don't have a direct edit URL
      alias_method :human_edit_url, :human_url
    end # Dashboard
  end # Models
end # Doggy
