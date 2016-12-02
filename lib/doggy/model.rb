# encoding: utf-8

require "json"
require "parallel"
require "uri"
require "virtus"

module Doggy
  class Model
    include Virtus.model

    # This stores the path on disk. We don't define it as a model attribute so
    # it doesn't get serialized.
    attr_accessor :path

    # indicates whether an object locally deleted
    attr_accessor :is_deleted

    # This stores whether the resource has been loaded locally or remotely.
    attr_accessor :loading_source

    class << self
      attr_accessor :root

      def find(id)
        attributes = request(:get, resource_url(id))
        return if attributes['errors']
        resource   = new(attributes)

        resource.loading_source = :remote
        resource
      end

      def all_local_resources
        @all_local_resources ||= Parallel.map((Dir[Doggy.object_root.join("**/*.json")])) do |file|
          raw = File.read(file, encoding: 'utf-8')
          begin
            attributes = JSON.parse(raw)
          rescue JSON::ParserError
            Doggy.ui.error "Could not parse #{ file }."
            next
          end
          resource = infer_type(attributes).new(attributes)
          resource.path = file
          resource.loading_source = :local
          resource
        end
      end

      def changed_resources
        repo = Rugged::Repository.new(Doggy.object_root.parent.to_s)
        repo.diff(current_sha, 'HEAD').each_delta.map do |delta|
          new_file_path = delta.new_file[:path]
          next unless new_file_path.match(/\Aobjects\//)
          is_deleted = delta.status == :deleted
          oid = is_deleted ? delta.old_file[:oid] : delta.new_file[:oid]
          begin
            attributes = JSON.parse(repo.read(oid).data)
          rescue JSON::ParserError
            Doggy.ui.error("Could not parse #{ new_file_path }. Skipping...")
            next
          end
          resource = infer_type(attributes).new(attributes)
          resource.loading_source = :local
          resource.path = Doggy.object_root.parent.join(new_file_path).to_s
          resource.is_deleted = is_deleted
          resource
        end.compact
      end

      def infer_type(attributes)
        has_key = ->(key) { attributes.has_key?(key.to_s) || attributes.has_key?(key.to_sym) }
        return Models::Dashboard if has_key.call('graphs')
        return Models::Monitor   if has_key.call('message')
        return Models::Screen    if has_key.call('board_title')
      end

      def request(method, url, body = nil)
        uri = URI(url)

        if uri.query
          uri.query = "api_key=#{ Doggy.api_key }&application_key=#{ Doggy.application_key }" + '&' + uri.query
        else
          uri.query = "api_key=#{ Doggy.api_key }&application_key=#{ Doggy.application_key }"
        end

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        request = case method
                  when :get    then Net::HTTP::Get.new(uri.request_uri)
                  when :post   then Net::HTTP::Post.new(uri.request_uri)
                  when :put    then Net::HTTP::Put.new(uri.request_uri)
                  when :delete then Net::HTTP::Delete.new(uri.request_uri)
                  end

        request.content_type = 'application/json'
        request.body = body if body

        response = http.request(request)
        response.body ? JSON.parse(response.body) : nil
      end

      def current_sha
        now = Time.now.to_i
        month_ago = now - 3600 * 24 * 30
        result = request(:get, "https://app.datadoghq.com/api/v1/events?start=#{ month_ago }&end=#{ now }&tags=audit,shipit")
        result['events'][0]['text'] # most recetly deployed SHA
      end

      def emit_shipit_deployment
        return unless ENV['SHIPIT']

        request(:post, 'https://app.datadoghq.com/api/v1/events', {
          title: "ShipIt Deployment by #{ENV['USER']}",
          text: ENV['REVISION'],
          tags: %w(audit shipit),
          date_happened: Time.now.to_i,
          priority: 'normal',
          source_type_name: 'shipit'
        }.to_json)
      end

      def sort_by_key(hash, &block)
        hash.keys.sort(&block).reduce({}) do |seed, key|
          seed[key] = hash[key]
          if seed[key].is_a?(Hash)
            seed[key] = Doggy::Model.sort_by_key(seed[key], &block)
          elsif seed[key].is_a?(Array)
            seed[key].each_with_index { |e, i| seed[key][i] = sort_by_key(e, &block) if e.is_a?(Hash) }
          end
          seed
        end
      end

      protected

      def resource_url(id = nil)
        raise NotImplementedError, "#resource_url has to be implemented."
      end
    end # class << self

    def initialize(attributes = nil)
      root_key = self.class.root

      return super unless attributes && root_key
      return super unless attributes[root_key].is_a?(Hash)

      attributes = attributes[root_key]
      super(attributes)
    end

    def save_local
      ensure_read_only!
      self.path ||= Doggy.object_root.join("#{prefix}-#{id}.json")
      File.open(@path, 'w') { |f| f.write(JSON.pretty_generate(to_h)) }
    end

    def to_h
      Doggy::Model.sort_by_key(super)
    end

    def validate
      # NotImplemented
    end

    def save
      ensure_managed_emoji!
      validate

      body = JSON.dump(to_h)
      if !id then
        attributes = request(:post, resource_url, body)
        self.id    = self.class.new(attributes).id
        save_local
        Doggy.ui.say "Created #{ path }"
      else
        request(:put, resource_url(id), body)
        Doggy.ui.say "Updated #{ path }"
      end
    end

    def destroy
      request(:delete, resource_url(id))
    end

    def destroy_local
      File.delete(@path)
    end

    protected

    def resource_url(id = nil)
      self.class.resource_url(id)
    end

    def request(method, uri, body = nil)
      self.class.request(method, uri, body)
    end
  end # Model
end # Doggy

