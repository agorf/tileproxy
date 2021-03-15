require 'yaml'

require_relative '../service'

module Tileproxy
  module Middleware
    class ServiceLoader
      SERVICES = YAML.safe_load(open('services.yml')).freeze

      def initialize(app)
        @app = app
      end

      def call(path)
        service_name = path.fetch(:service)

        if !SERVICES.key?(service_name)
          return [
            Rack::Utils.status_code(:not_found),
            { 'Content-Type' => 'text/plain' },
            [%(Service "#{service_name}" not found. Available services: #{SERVICES.keys.sort.join(', ')})]
          ]
        end

        service_config = SERVICES.fetch(service_name)
        service = Service.new(service_name, service_config)
        @app.call(path, service)
      end
    end
  end
end
