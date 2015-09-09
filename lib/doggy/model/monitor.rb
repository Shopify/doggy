module Doggy
  class Monitor
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

    def self.download_all
      ids = Doggy.client.dog.get_all_alerts[1]['alerts'].map { |d| d['id'] }
      puts "Downloading #{ids.size} alerts..."
      Doggy.clean_dir(Doggy.alerts_path)
      download(ids)
    rescue => e
      puts "Exception: #{e.message}"
    end

    def self.upload_all
      ids = Dir[Doggy.alerts_path.join('*')].map { |f| File.basename(f, '.*') }
      puts "Uploading #{ids.size} alerts from #{Doggy.alerts_path}: #{ids.join(', ')}"
      upload(ids)
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

    def self.create(name)
      # Adding a placeholder query as it's a mandatory parameter
      item = new(name: name, query: 'avg(last_1m):avg:system.load.1{*} > 100')
      item.push
      item.save
    end

    def raw
      @raw ||= begin
        alert = Doggy.client.dog.get_monitor(@id)[1]
        alert.delete('state')
        alert.delete('overall_state')
        alert['options'].delete('silenced')
        alert.sort.to_h
      end
    end

    def raw_local
      return unless File.exists?(path)
      @raw_local ||= Doggy.serializer.load(File.read(path))
    end

    def save
      puts raw['errors'] and return if raw['errors'] # do now download an item if it doesn't exist
      return if raw['name'] =~ Doggy::DOG_SKIP_REGEX
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
      if @id
        return unless File.exists?(path)

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
      else
        result = Doggy.client.dog.monitor('metric alert', @query, name: @name)
        @id = result[1]['id']
      end
    end

    def delete
      Doggy.client.dog.delete_alert(@id)
      File.unlink(path)
    end

    private

    def path
      "#{Doggy.alerts_path}/#{@id}.json"
    end

    def mute_state_for(id)
      if remote_state = Doggy.all_remote_monitors.detect { |key, value| key == [ 'monitor', id.to_i ] }
        remote_state[1]['options']['silenced'] if remote_state[1]['options']
      end
    end
  end
end
