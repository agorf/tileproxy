require 'rack/mime'
require 'rack/utils'

module Tileproxy
  module Middleware
    class ExtensionValidator
      def initialize(app)
        @app = app
      end

      def call(env)
        extension = env.fetch('tileproxy.path').fetch(:ext)
        content_type = Rack::Mime::MIME_TYPES[extension.downcase]

        if content_type.nil?
          return [
            Rack::Utils.status_code(:bad_request),
            { 'Content-Type' => 'text/plain' },
            ["Unknown Content-Type for requested file extension #{extension}"]
          ]
        end

        if content_type.split('/', 2)[0] != 'image'
          return [
            Rack::Utils.status_code(:bad_request),
            { 'Content-Type' => 'text/plain' },
            ["Non-image Content-Type #{content_type} for requested file extension #{extension}"]
          ]
        end

        env['tileproxy.request_content_type'] = content_type

        @app.call(env)
      end
    end
  end
end
