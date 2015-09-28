module Doggy
  class Screen
    def self.upload_all
      objects = Doggy.all_local_items.find_all { |(type, id), object| type == 'screen' }
      puts "Uploading #{objects.size} screens"
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

    def self.edit(id)
      system %{open "https://app.datadoghq.com/screen/#{id}"}
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
      @description = options[:description] || raw_local
    end

    def raw
      @raw ||= begin
        status, result = Doggy.client.dog.get_screenboard(@id)
        result && result.sort.to_h
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
      return unless Doggy.determine_type(raw_local) == 'screen'
      if @id
        SharedHelpers.with_retry do
          Doggy.client.dog.update_screenboard(@id, @description)
        end
      else
        SharedHelpers.with_retry do
          result = Doggy.client.dog.create_screenboard(@description)
        end
        @id = result[1]['id']
        @description = result[1]
      end
    end

    def delete
      Doggy.client.dog.delete_screenboard(@id)
    end

    private

    def path
      "#{Doggy.objects_path}/#{@id}.json"
    end
  end
end
