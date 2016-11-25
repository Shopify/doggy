# encoding: utf-8

module Doggy
  module Models
    class Monitor < Doggy::Model
      class Options
        include Virtus.model
        attr_accessor :monitor

        attribute :silenced,           Hash
        attribute :thresholds,         Hash
        attribute :notify_audit,       Boolean
        attribute :notify_no_data,     Boolean
        attribute :no_data_timeframe,  Integer
        attribute :timeout_h,          Integer
        attribute :escalation_message, String
        attribute :renotify_interval,  Integer
        attribute :locked,             Boolean

        def to_h
          return super unless monitor.id && monitor.loading_source == :local

          # Pull remote silenced state. If we don't send this value, Datadog
          # assumes that we want to unmute the monitor.
          remote_monitor = Monitor.find(monitor.id)
          self.silenced  = remote_monitor.options.silenced if remote_monitor.options
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

      def prefix
        'monitor'
      end

      def ensure_read_only!
        if options
          self.options.locked = true
        else
          self.options = Options.new(locked: true)
        end
      end

      def self.resource_url(id = nil)
        "https://app.datadoghq.com/api/v1/monitor".tap do |base_url|
          base_url << "/#{ id }" if id
        end
      end

      def initialize(attributes = nil)
        super(attributes)

        options.monitor = self if options
      end

      def managed?
        !(name =~ Doggy::DOG_SKIP_REGEX)
      end

      def ensure_managed_emoji!
        return unless managed?
        return if self.name =~ /\xF0\x9F\x90\xB6/
        self.name += " \xF0\x9F\x90\xB6"
      end

      def validate
        ensure_renotify_interval_valid
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

      private

      def ensure_renotify_interval_valid
        return unless options && options.renotify_interval && options.renotify_interval.to_i > 0

        allowed_renotify_intervals = [10,20,30,40,50,60,90,120,180,240,300,360,720,1440] # minutes
        best_matching_interval = allowed_renotify_intervals.min_by { |x| (x.to_f - options.renotify_interval).abs }
        puts "WARN: Monitor #{self.id} uses invalid escalation interval (renotify_interval) #{options.renotify_interval}, using #{best_matching_interval} instead"
        options.renotify_interval = best_matching_interval
      end
    end # Monitor
  end # Models
end # Doggy

