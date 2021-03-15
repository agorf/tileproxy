require 'rack/utils'

require_relative '../service'

module Tileproxy
  module Middleware
    class ServiceValidator
      def initialize(app)
        @app = app
      end

      def call(env)
        service_name = env.fetch('PATH_SERVICE')

        if !SERVICES.key?(service_name)
          return [
            Rack::Utils.status_code(:not_found),
            { 'Content-Type' => 'text/plain' },
            [%(Service "#{service_name}" not found. Available services: #{SERVICES.keys.sort.join(', ')})]
          ]
        end

        env['SERVICE_NAME'] = service_name

        @app.call(env)
      end
    end
  end
end
