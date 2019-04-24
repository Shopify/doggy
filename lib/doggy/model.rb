# frozen_string_literal: true

require "json"
require "parallel"
require "uri"
require "active_support/core_ext/hash/keys"

module Doggy
  class Model
    # Denormalized object attributes.
    attr_accessor :attributes

    # This stores the path on disk. We don't define it as a model attribute so
    # it doesn't get serialized.
    attr_accessor :path

    # Indicates whether an object locally deleted
    attr_accessor :is_deleted

    # This stores whether the resource has been loaded locally or remotely.
    attr_accessor :loading_source

    class << self
      def find(id)
        attributes = request(:get, resource_url(id), nil, [404, 400])
        if self == Doggy::Models::Dashboard
          attributes = request(:get, resource_url(id, "dash"), nil, [404, 400]) if attributes['errors']
          attributes = request(:get, resource_url(id, "screen"), nil, [404, 400]) if attributes['errors']
        end
        return if attributes['errors']
        resource = new(attributes)

        resource.loading_source = :remote
        resource
      end

      def find_local(param)
        resources = Doggy::Model.all_local_resources
        param = param.to_s
        if (param =~ /^[0-9]+$/) || (param =~ /^[a-z0-9]+-[a-z0-9]+-[a-z0-9]+$/)
          id = param
          return resources.find { |res| res.id == id.to_s || res.id == id.to_i }
        end
        if (id = param[%r{(dashboard/|monitors#)(\d+)}i, 2])
          return resources.find { |res| res.id == id.to_s || res.id == id.to_i }
        end
        full_path = File.expand_path(param.gsub('objects/', ''), Doggy.object_root)
        resources.find { |res| res.path == full_path }
      end

      def all_local_resources
        @@all_local_resources ||= Parallel.map(Dir[Doggy.object_root.join("**/*.json")]) do |file|
          raw = File.read(file, encoding: 'utf-8')
          begin
            attributes = JSON.parse(raw)
          rescue JSON::ParserError
            Doggy.ui.error("Could not parse #{file}.")
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
        diff = repo.diff(current_sha, 'HEAD')
        diff.find_similar!
        diff.each_delta.map do |delta|
          new_file_path = delta.new_file[:path]
          next unless new_file_path =~ %r{\Aobjects/}
          is_deleted = delta.status == :deleted
          oid = is_deleted ? delta.old_file[:oid] : delta.new_file[:oid]
          begin
            attributes = JSON.parse(repo.read(oid).data)
          rescue JSON::ParserError
            Doggy.ui.error("Could not parse #{new_file_path}. Skipping...")
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
        attributes.key?("message") ? Models::Monitor : Models::Dashboard
      end

      def request(method, url, body = nil, accepted_errors = nil)
        uri = URI(url)

        uri.query = if uri.query
          "api_key=#{Doggy.api_key}&application_key=#{Doggy.application_key}" + '&' + uri.query
        else
          "api_key=#{Doggy.api_key}&application_key=#{Doggy.application_key}"
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
        parsed_response = response.body.present? ? JSON.parse(response.body) : nil

        unless accepted_response(response.code.to_i, accepted_errors)
          raise DoggyError, "Unexpected response code #{response.code} for #{url}, body: #{parsed_response}"
        end
        parsed_response
      end

      def accepted_response(code, accepted_errors = nil)
        if !accepted_errors.nil? && accepted_errors.include?(code)
          true
        else
          code >= 200 && code < 400
        end
      end

      def current_sha
        now = Time.now.to_i
        month_ago = now - 3600 * 24 * 30
        result = request(:get, "https://app.datadoghq.com/api/v1/events?start=#{month_ago}&end=#{now}&tags=audit,shipit")
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
          source_type_name: 'shipit',
        }.to_json)
      end

      def sort_by_key(hash)
        hash
      end

      protected

      def resource_url(_id = nil)
        raise NotImplementedError, "#resource_url has to be implemented."
      end
    end # class << self

    def ==(other)
      to_h == other.to_h
    end

    def initialize(attributes = {})
      @attributes = attributes.deep_stringify_keys

      @attributes["id"] = @attributes["id"].to_s if @attributes["id"]
      @attributes["options"] ||= {} if self.class == Doggy::Models::Monitor
    end

    def save_local
      ensure_read_only!
      self.path ||= Doggy.object_root.join("#{prefix}-#{id}.json")
      File.open(@path, 'w') { |f| f.write(JSON.pretty_generate(to_h)) }
    end

    def to_h
      Doggy::Model.sort_by_key(attributes)
    end

    def validate
      # NotImplemented
    end

    def save
      ensure_managed_emoji!
      validate

      body = JSON.dump(to_h)
      if !id
        attributes = request(:post, resource_url, body)
        self.id    = self.class.new(attributes).id
        save_local
        Doggy.ui.say("Created #{path}")
      else
        request(:put, resource_url(id), body)
        Doggy.ui.say("Updated #{path}")
      end
    end

    def destroy
      self.class.request(:delete, resource_url(id), nil, [404, 400])
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
