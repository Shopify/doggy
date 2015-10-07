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

    # This stores whether the resource has been loaded locally or remotely.
    attr_accessor :loading_source

    class << self
      def root=(root)
        @root = root.to_s
      end

      def root
        @root || nil
      end

      def find(id)
        attributes = request(:get, resource_url(id))
        resource   = new(attributes)

        resource.loading_source = :remote
        resource
      end

      def assign_paths(remote_resources, local_resources)
        remote_resources.each do |remote|
          local = local_resources.find { |l| l.id == remote.id }
          next unless local

          remote.path = local.path
        end
      end

      def all
        collection = request(:get, resource_url)
        if collection.is_a?(Hash) && collection.keys.length == 1
          collection = collection.values.first
        end

        ids = collection
          .map    { |record| new(record) }
          .select { |instance| instance.managed? }
          .map    { |instance| instance.id }

        Parallel.map(ids) { |id| find(id) }
      end

      def all_local(only_changed: false)
        @all_local ||= begin
                         # TODO: Add serializer support here
                         if only_changed
                           files   = Doggy.modified(Doggy::Model.current_sha).map { |i| Doggy.object_root.join(i).to_s }
                         else
                           files   = Dir[Doggy.object_root.join("**/*.json")]
                         end
                         resources = Parallel.map(files) do |file|
                           raw = File.read(file, encoding: 'utf-8')

                           begin
                             attributes = JSON.parse(raw)
                           rescue JSON::ParserError
                             Doggy.ui.error "Could not parse #{ file }."
                             next
                           end

                           next unless infer_type(attributes) == self

                           resource                = new(attributes)
                           resource.path           = file
                           resource.loading_source = :local
                           resource
                         end

                         resources.compact
                       end
      end

      def infer_type(attributes)
        return Models::Dashboard if attributes['graphs']
        return Models::Monitor   if attributes['message']
        return Models::Screen    if attributes['board_title']
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
                  when :get  then Net::HTTP::Get.new(uri.request_uri)
                  when :post then Net::HTTP::Post.new(uri.request_uri)
                  when :put  then Net::HTTP::Put.new(uri.request_uri)
                  end

        request.content_type = 'application/json'
        request.body = body if body

        response = http.request(request)
        JSON.parse(response.body)
      end

      def current_sha
        now = Time.now.to_i
        month_ago = now - 3600 * 24 * 30
        result = request(:get, "https://app.datadoghq.com/api/v1/events?start=#{ month_ago }&end=#{ now }&tags=audit,shipit")
        result['events'][0]['text'] # most recetly deployed SHA
      end

      def emit_shipit_deployment
        request(:post, 'https://app.datadoghq.com/api/v1/events', {
          title: "ShipIt Deployment by #{ENV['USER']}",
          text: ENV['REVISION'],
          tags: %w(audit shipit),
          date_happened: Time.now.to_i,
          priority: 'normal',
          source_type_name: 'shipit'
        }.to_json)
      end

      protected

      def resource_url(id = nil)
        raise NotImplementedError, "#resource_url has to be implemented."
      end
    end

    def initialize(attributes = nil)
      root_key = self.class.root

      return super unless attributes && root_key
      return super unless attributes[root_key].is_a?(Hash)

      attributes = attributes[root_key]
      super(attributes)
    end

    def save_local
      @path ||= Doggy.object_root.join("#{ id }.json")
      File.open(@path, 'w') { |f| f.write(JSON.pretty_generate(to_h)) }
    end

    def save
      ensure_managed_emoji!

      body = JSON.dump(to_h)
      if !id then
        attributes = request(:post, resource_url, body)
        self.id    = self.class.new(attributes).id
        save_local
      else
        request(:put, resource_url(id), body)
      end
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

