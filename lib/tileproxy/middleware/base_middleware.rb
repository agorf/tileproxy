require 'rack/utils'

module Tileproxy
  module Middleware
    class BaseMiddleware
      def http_error(status, message)
        [
          Rack::Utils.status_code(status),
          { 'content-type' => 'text/plain' },
          [message]
        ]
      end
    end
  end
end
