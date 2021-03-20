require 'rack/static'

require_relative 'base_middleware'

module Tileproxy
  module Middleware
    class Static < BaseMiddleware
      def initialize(app = nil, services:, tile_cache_path:, cascade: false)
        @app = app
        @services = services
        @tile_cache_path = tile_cache_path
        @cascade = cascade
      end

      def call(env)
        Rack::Static.new(
          @app,
          urls: service_paths,
          root: @tile_cache_path,
          cascade: @cascade
        ).call(env)
      end

      private def service_paths
        @services.keys.map { |name| "/#{name}/" }
      end
    end
  end
end
