require_relative 'middleware/static'
require_relative 'middleware/tile_downloader'
require_relative 'middleware/extension_validator'
require_relative 'middleware/service_validator'
require_relative 'middleware/path_validator'

module Tileproxy
  class App
    def initialize(services:, tile_cache_path:)
      @services = services
      @tile_cache_path = tile_cache_path
    end

    def call(env)
      # Order is last to first
      app = Middleware::Static.new(
        services: @services,
        tile_cache_path: @tile_cache_path
      )
      app = Middleware::TileDownloader.new(
        app,
        services: @services,
        tile_cache_path: @tile_cache_path
      )
      app = Middleware::ExtensionValidator.new(app)
      app = Middleware::ServiceValidator.new(app, services: @services)
      app = Middleware::PathValidator.new(app)
      app = Middleware::Static.new(
        app,
        services: @services,
        tile_cache_path: @tile_cache_path,
        cascade: true
      )
      app.call(env)
    end
  end
end
