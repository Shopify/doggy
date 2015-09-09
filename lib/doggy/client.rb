class Dogapi::APIService
  attr_reader :api_key, :application_key # as they are useless in the parent class
end

module Doggy
  class Client
    def api_key
      @api_key ||= ENV.fetch('DATADOG_API_KEY', ejson_config[:datadog_api_key])
    rescue => e
      puts "[DogSync#api_key] Exception: #{e.message}"
      raise
    end

    def app_key
      @app_key ||= ENV.fetch('DATADOG_APP_KEY', ejson_config[:datadog_app_key])
    rescue => e
      puts "[DogSync#app_key] Exception: #{e.message}"
      raise
    end

    def dog
      @dog ||= Dogapi::Client.new(api_key, app_key)
    end

    def api_service
      @api_service ||= Dogapi::APIService.new(api_key, app_key)
    end

    def api_service_params
      @api_service_params ||= { api_key: Doggy.client.api_service.api_key, application_key: Doggy.client.api_service.application_key }
    end

    private

    def ejson_config
      @ejson_config ||= begin
        if File.exists?('secrets.json')
          secrets = JSON.parse(File.read('secrets.json'))
          { datadog_api_key: secrets['datadog_api_key'], datadog_app_key: secrets['datadog_app_key'] }
        else
          {}
        end
      end
    end
  end
end
