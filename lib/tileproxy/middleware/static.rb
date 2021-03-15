require 'rack/static'

require_relative '../../tileproxy'
require_relative 'base_middleware'

module Tileproxy
  module Middleware
    class Static < BaseMiddleware
      def initialize(app = nil, services:, cascade: false)
        @app = app
        @services = services
        @cascade = cascade
      end

      def call(env)
        Rack::Static.new(
          @app,
          urls: service_paths,
          root: TILE_CACHE_PATH,
          cascade: @cascade
        ).call(env)
      end

      private def service_paths
        @services.keys.map { |name| "/#{name}/" }
      end
    end
  end
end
