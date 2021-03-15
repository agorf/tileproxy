require 'rack/mime'

require_relative 'base_middleware'

module Tileproxy
  module Middleware
    class ExtensionValidator < BaseMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        extension = env.fetch('tileproxy.path').fetch(:ext)
        content_type = Rack::Mime::MIME_TYPES[extension.downcase]

        if content_type.nil?
          return http_error(
            :bad_request,
            "Unknown Content-Type for requested file extension #{extension}"
          )
        end

        if content_type.split('/', 2)[0] != 'image'
          return http_error(
            :bad_request,
            "Non-image Content-Type #{content_type} for requested file extension #{extension}"
          )
        end

        env['tileproxy.request_content_type'] = content_type

        @app.call(env)
      end
    end
  end
end
