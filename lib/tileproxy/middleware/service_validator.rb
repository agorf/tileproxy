require_relative 'base_middleware'

module Tileproxy
  module Middleware
    class ServiceValidator < BaseMiddleware
      def initialize(app, service_names)
        @app = app
        @service_names = service_names
      end

      def call(env)
        service_name = env.fetch('tileproxy.path').fetch(:service)

        if !@service_names.include?(service_name)
          return http_error(
            :not_found,
            %(Service "#{service_name}" not found. Available services: #{@service_names.sort.join(', ')})
          )
        end

        env['tileproxy.service_name'] = service_name

        @app.call(env)
      end
    end
  end
end
