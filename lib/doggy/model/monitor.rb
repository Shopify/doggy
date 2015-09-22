module Doggy
  class Monitor
    def self.upload_all
      objects = all_local_items.find_all { |(type, id), object| type == 'monitor' }
      puts "Uploading #{objects.size} monitors"
      upload(objects.map { |(type, id), object| id })
    rescue => e
      puts "Exception: #{e.message}"
    end

    def self.download(ids)
      Doggy::Worker.new(threads: Doggy::Worker::CONCURRENT_STREAMS) { |id| new(id: id).save }.call([*ids])
    end

    def self.upload(ids)
      Doggy::Worker.new(threads: Doggy::Worker::CONCURRENT_STREAMS) { |id| new(id: id).push }.call([*ids])
    end

    def self.mute(ids)
      Doggy::Worker.new(threads: Doggy::Worker::CONCURRENT_STREAMS) { |id| new(id: id).mute }.call([*ids])
    end

    def self.unmute(ids)
      Doggy::Worker.new(threads: Doggy::Worker::CONCURRENT_STREAMS) { |id| new(id: id).unmute }.call([*ids])
    end

    def self.edit(id)
      system %{open "https://app.datadoghq.com/monitors##{id}"}
      if SharedHelpers.agree("Are you done?")
        puts 'Here is the output of your edit:'
        puts Doggy::Serializer::Json.dump(new(id: id).raw)
      else
        puts "run, rabbit run / dig that hole, forget the sun / and when at last the work is done / don't sit down / it's time to dig another one"
        edit(id)
      end
    end

    def initialize(**options)
      @id = options[:id]
      @query = options[:query]
      @silenced = options[:silenced]
      @name = options[:name]
      @timeout_h = options[:timeout_h]
      @message = options[:message]
      @notify_audit = options[:notify_audit]
      @notify_no_data = options[:notify_no_data]
      @renotify_interval = options[:renotify_interval]
      @escalation_message = options[:escalation_message]
      @no_data_timeframe = options[:no_data_timeframe]
      @silenced_timeout_ts = options[:silenced_timeout_ts]
    end

    def raw
      @raw ||= begin
        status, alert = Doggy.client.dog.get_monitor(@id)

        return if status != '200'

        alert.delete('state')                                              # delete unnecessary state
        alert.delete('overall_state')                                      # delete unnecessary state
        if alert['options']
          alert['options'].delete('silenced')                              # delete unnecessary state
          alert['options'] = alert['options'].sort.to_h                    # sort option keys; DataDog response is not ordered
        end
        alert && alert.sort.to_h
      end
    end

    def raw_local
      return unless File.exists?(path)
      @raw_local ||= Doggy.serializer.load(File.read(path))
    end

    def save
      return if raw.nil? || raw.empty?               # do not save if it's empty
      return if raw['errors']                        # do not save if there are any errors
      return if raw['name'] =~ Doggy::DOG_SKIP_REGEX # do not save if it had skip tag in title

      File.write(path, Doggy.serializer.dump(raw))
    end

    def mute
      Doggy.client.dog.mute_monitor(@id)
    end

    def unmute
      Doggy.client.dog.unmute_monitor(@id)
    end

    def push
      return if @name =~ Doggy::DOG_SKIP_REGEX
      return unless Doggy.determine_type(raw_local) == 'monitor'

      # Managed by doggy (TM)
      @name = @name =~ MANAGED_BY_DOGGY_REGEX ? @name : @name + " 🐶"

      if @id
        return unless File.exists?(path)

        SharedHelpers.with_retry do
          Doggy.client.dog.update_monitor(@id, @query || raw_local['query'], {
            name: @name || raw_local['name'],
            timeout_h: @timeout_h || raw_local['timeout_h'],
            message: @message || raw_local['message'],
            notify_audit: @notify_audit || raw_local['notify_audit'],
            notify_no_data: @notify_no_data || raw_local['notify_no_data'],
            renotify_interval: @renotify_interval || raw_local['renotify_interval'],
            escalation_message: @escalation_message || raw_local['escalation_message'],
            no_data_timeframe: @no_data_timeframe || raw_local['no_data_timeframe'],
            silenced_timeout_ts: @silenced_timeout_ts || raw_local['silenced_timeout_ts'],
            options: {
              silenced: mute_state_for(@id),
            },
          })
        end
      else
        SharedHelpers.with_retry do
          result = Doggy.client.dog.monitor('metric alert', @query, name: @name)
        end
        @id = result[1]['id']
      end
    end

    def delete
      Doggy.client.dog.delete_alert(@id)
    end

    private

    def path
      "#{Doggy.objects_path}/#{@id}.json"
    end

    def mute_state_for(id)
      if remote_state = Doggy.all_remote_monitors.detect { |key, value| key == [ 'monitor', id.to_i ] }
        remote_state[1]['options']['silenced'] if remote_state[1]['options']
      end
    end
  end
end
