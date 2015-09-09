module Doggy
  class Dash
    def initialize(**options)
      @id = options[:id]
      @title = options[:title] || raw_local['title']
      @description = options[:description] || raw_local['description']
      @graphs = options[:graphs] || raw_local['graphs']
      @template_variables = options[:template_variables] || raw_local['template_variables']
    end

    def self.download_all
      ids = Doggy.client.dog.get_dashboards[1]['dashes'].map { |d| d['id'] }
      puts "Downloading #{ids.size} dashboards..."
      Doggy.clean_dir(Doggy.dashes_path)
      download(ids)
    rescue => e
      puts "Exception: #{e.message}"
    end

    def self.upload_all
      ids = Dir[Doggy.dashes_path.join('*')].map { |f| File.basename(f, '.*') }
      puts "Uploading #{ids.size} dashboards from #{Doggy.dashes_path}: #{ids.join(', ')}"
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
      # This graphs placeholder is required as you cannot create an empty dashboard via API
      dash = new(title: name, description: '', graphs: [{
        "definition" => {
          "events" => [],
          "requests" => [
            {"q" => "avg:system.mem.free{*}"}
          ],
          "viz" => "timeseries"
        },
        "title" => "Average Memory Free"
      }])
      dash.push
      dash.save
    end

    def raw
      @raw ||= begin
        result = Doggy.client.dog.get_dashboard(@id)
        result && result[1]['dash'] && result[1]['dash'].sort.to_h
      end
    end

    def raw_local
      return {} unless File.exists?(path)
      @raw_local ||= Doggy.serializer.load(File.read(path))
    end

    def save
      puts raw['errors'] and return if raw['errors'] # do now download an item if it doesn't exist
      return if raw['title'] =~ Doggy::DOG_SKIP_REGEX
      File.write(path, Doggy.serializer.dump(raw))
    end

    def push
      return unless File.exists?(path)
      return if @title =~ Doggy::DOG_SKIP_REGEX
      if @id
        Doggy.client.dog.update_dashboard(@id, @title, @description, @graphs, @template_variables)
      else
        dash = Doggy.client.dog.create_dashboard(@title, @description, @graphs)
        # FIXME: Remove duplication
        @id = dash[1]['id']
        @graphs = dash[1]['graphs']
      end
    end

    def delete
      Doggy.client.dog.delete_dashboard(@id)
      File.unlink(path)
    end

    private

    def path
      "#{Doggy.dashes_path}/#{@id}.json"
    end
  end
end
