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

      def all_local
        @all_local ||= begin
                         # TODO: Add serializer support here
                         files   = Dir[Doggy.object_root.join("**/*.json")]
                         resources = Parallel.map(files) do |file|
                           raw = File.read(file)

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
        uri.query = "api_key=#{ Doggy.api_key }&application_key=#{ Doggy.application_key }"

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

