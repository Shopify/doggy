module Doggy
  class Screen
    def initialize(**options)
      @id = options[:id]
      @description = options[:description] || raw_local
    end

    def self.download_all
      ids = Doggy.client.dog.get_all_screenboards[1]['screenboards'].map { |d| d['id'] }
      puts "Downloading #{ids.size} screenboards..."
      Doggy.clean_dir(Doggy.screens_path)
      download(ids)
    rescue => e
      puts "Exception: #{e.message}"
    end

    def self.upload_all
      ids = Dir[Doggy.screens_path.join('*')].map { |f| File.basename(f, '.*') }
      puts "Uploading #{ids.size} screenboards from #{Doggy.screens_path}: #{ids.join(', ')}"
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

    def self.create(name)
      item = new(description: { 'board_title' => name, 'widgets' => [] })
      item.push
      item.save
    end

    def raw
      @raw ||= begin
        result = Doggy.client.dog.get_screenboard(@id)
        result && result[1] && result[1].sort.to_h
      end
    end

    def raw_local
      return {} unless File.exists?(path)
      @raw_local ||= Doggy.serializer.load(File.read(path))
    end

    def save
      return if raw['errors'] # do now download an item if it doesn't exist
      return if raw['board_title'] =~ Doggy::DOG_SKIP_REGEX
      return if raw.empty?
      File.write(path, Doggy.serializer.dump(raw))
    end

    def push
      return if @description =~ Doggy::DOG_SKIP_REGEX
      if @id
        Doggy.with_retry do
          Doggy.client.dog.update_screenboard(@id, @description)
        end
      else
        Doggy.with_retry do
          result = Doggy.client.dog.create_screenboard(@description)
        end
        @id = result[1]['id']
        @description = result[1]
      end
    end

    def delete
      Doggy.client.dog.delete_screenboard(@id)
      File.unlink(path)
    end

    private

    def path
      "#{Doggy.screens_path}/#{@id}.json"
    end
  end
end
