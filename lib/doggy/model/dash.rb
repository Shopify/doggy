module Doggy
  class Dash
    def self.upload_all
      objects = Doggy.all_local_items.find_all { |(type, id), object| type == 'dash' }
      puts "Uploading #{objects.size} dashboards"
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
      system %{open "https://app.datadoghq.com/dash/#{id}"}
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
      @title = options[:title] || raw_local['title']
      @description = options[:description] || raw_local['description']
      @graphs = options[:graphs] || raw_local['graphs']
      @template_variables = options[:template_variables] || raw_local['template_variables']
    end

    def raw
      @raw ||= begin
        status, result = Doggy.client.dog.get_dashboard(@id)
        result && result['dash'] && result['dash'].sort.to_h || {}
      end
    end

    def raw_local
      return {} unless File.exists?(path)
      @raw_local ||= begin
        object = Doggy.serializer.load(File.read(path))
        object['dash'] ? object['dash'] : object
      end
    end

    def save
      return if raw.nil? || raw.empty?                # do not save if it's empty
      return if raw['errors']                         # do not save if there are any errors
      return if raw['title'] =~ Doggy::DOG_SKIP_REGEX # do not save if it had skip tag in title

      File.write(path, Doggy.serializer.dump(raw))
    end

    def push
      return unless File.exists?(path)
      return if @title =~ Doggy::DOG_SKIP_REGEX
      return unless Doggy.determine_type(raw_local) == 'dash'

      # Managed by doggy (TM)
      @title = @title =~ MANAGED_BY_DOGGY_REGEX ? @title : @title + " 🐶"

      if @id
        SharedHelpers.with_retry do
          Doggy.client.dog.update_dashboard(@id, @title, @description, @graphs, @template_variables)
        end
      else
        SharedHelpers.with_retry do
          dash = Doggy.client.dog.create_dashboard(@title, @description, @graphs)
        end
        # FIXME: Remove duplication
        @id = dash[1]['id']
        @graphs = dash[1]['graphs']
      end
    end

    def delete
      Doggy.client.dog.delete_dashboard(@id)
    end

    private

    def path
      "#{Doggy.objects_path}/#{@id}.json"
    end
  end
end
