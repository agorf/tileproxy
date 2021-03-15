require 'rack/utils'

module Tileproxy
  module Middleware
    class BaseMiddleware
      def initialize(app)
        @app = app
      end

      def http_error(status, message)
        [
          Rack::Utils.status_code(status),
          { 'Content-Type' => 'text/plain' },
          [message]
        ]
      end
    end
  end
end
