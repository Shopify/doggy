# frozen_string_literal: true

module Doggy
  module Models
    class Monitor < Doggy::Model
      def id
        attributes["id"]
      end

      def id=(v)
        attributes["id"] = v
      end

      def name
        attributes["name"]
      end

      def name=(v)
        attributes["name"] = v
      end

      def locked
        attributes["options"]["locked"]
      end

      def locked=(v)
        attributes["options"]["locked"] = v
      end

      def silenced
        attributes["options"]["silenced"]
      end

      def silenced=(v)
        attributes["options"]["silenced"] = v
      end

      def prefix
        'monitor'
      end

      def ensure_read_only!
        attributes["options"]["locked"] = true
      end

      def refute_read_only!
        attributes["options"]["locked"] = false
      end

      def self.resource_url(id = nil, kind = "monitor")
        ["https://app.datadoghq.com/api/v1/#{kind}", id].compact.join("/")
      end

      def managed?
        name !~ Doggy::DOG_SKIP_REGEX
      end

      def ensure_managed_emoji!
        return unless managed?
        return if name =~ /🐶/
        self.name += " 🐶"
      end

      def validate
        ensure_renotify_interval_valid
      end

      def toggle_mute!(action, body = nil)
        return unless %w[mute unmute].include?(action) && id
        attributes = request(:post, "#{resource_url(id)}/#{action}", body)
        if (message = attributes['errors'])
          Doggy.ui.error(message)
        else
          self.attributes = attributes
          if (local_version = Doggy::Model.find_local(id))
            self.path = local_version.path
          end
          save_local
        end
      end

      def human_url
        "https://#{Doggy.base_human_url}/monitors##{id}"
      end

      def human_edit_url
        "https://#{Doggy.base_human_url}/monitors##{id}/edit"
      end

      private

      def ensure_renotify_interval_valid
        return unless attributes.dig("options", "renotify_interval") && attributes.dig("options", "renotify_interval").to_i > 0

        allowed_renotify_intervals = [10, 20, 30, 40, 50, 60, 90, 120, 180, 240, 300, 360, 720, 1440] # minutes
        best_matching_interval = allowed_renotify_intervals.min_by { |x| (x.to_f - attributes["options"]["renotify_interval"]).abs }
        puts "WARN: Monitor #{id} uses invalid escalation interval (renotify_interval) #{attributes["options"]["renotify_interval"]}, using #{best_matching_interval} instead"
        attributes["options"]["renotify_interval"] = best_matching_interval
      end
    end # Monitor
  end # Models
end # Doggy
