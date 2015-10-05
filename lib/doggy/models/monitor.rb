# encoding: utf-8

module Doggy
  module Models
    class Monitor < Doggy::Model
      class Options
        include Virtus.model
        attr_accessor :monitor

        attribute :silenced,           Hash
        attribute :notify_audit,       Boolean
        attribute :notify_no_data,     Boolean
        attribute :no_data_timeframe,  Integer
        attribute :timeout_h,          Integer
        attribute :escalation_message, String

        def to_h
          return super unless monitor.id && monitor.loading_source == :local

          # Pull remote silenced state. If we don't send this value, Datadog
          # assumes that we want to unmute the monitor.
          remote_monitor = Monitor.find(monitor.id)
          self.silenced  = remote_monitor.options.silenced
          super
        end
      end

      attribute :id,     Integer
      attribute :org_id, Integer
      attribute :name,   String

      attribute :message, String
      attribute :query,   String
      attribute :options, Options
      attribute :tags,    Array[String]
      attribute :type,    String
      attribute :multi,   Boolean

      def self.resource_url(id = nil)
        "https://app.datadoghq.com/api/v1/monitor".tap do |base_url|
          base_url << "/#{ id }" if id
        end
      end

      def initialize(attributes = nil)
        super(attributes)

        options.monitor = self
      end

      def managed?
        !(name =~ Doggy::DOG_SKIP_REGEX)
      end

      def ensure_managed_emoji!
        return unless managed?
        self.name += " \xF0\x9F\x90\xB6"
      end

      def mute
        return unless id
        request(:post, "#{ resource_url(id) }/mute")
      end

      def unmute
        return unless id
        request(:post, "#{ resource_url(id) }/unmute")
      end

      def human_url
        "https://app.datadoghq.com/monitors##{ id }"
      end

      def human_edit_url
        "https://app.datadoghq.com/monitors##{ id }/edit"
      end

      def to_h
        super.merge(options: options.to_h)
      end
    end # Monitor
  end # Models
end # Doggy

